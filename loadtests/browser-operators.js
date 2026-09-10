const fs = require("node:fs/promises")
const { chromium } = require("playwright")

const baseUrl = (process.env.BASE_URL || "http://host.docker.internal:3000").replace(/\/+$/, "")
const tournamentCount = Math.min(10, Math.max(1, Number(process.env.TOURNAMENT_COUNT || 1)))
const loadTestTournamentBaseId = 205
const tournamentIds = Array.from({ length: tournamentCount }, (_, index) => loadTestTournamentBaseId + index)
const email = process.env.OPERATOR_EMAIL || "test@test.com"
const password = process.env.OPERATOR_PASSWORD || "password"
const testDurationMs = Number(process.env.TEST_DURATION_SECONDS || 600) * 1000
const matchDurationMs = Math.max(2, Number(process.env.PER_TOURNAMENT_OPERATOR_MATCH_SECONDS || 50)) * 1000
const clockStartDelayMs = Math.max(0, Number(process.env.PER_TOURNAMENT_OPERATOR_CLOCK_START_DELAY_SECONDS || 10)) * 1000
const eventIntervalMs = Math.max(1, Number(process.env.PER_TOURNAMENT_OPERATOR_EVENT_INTERVAL_SECONDS || 10)) * 1000
const operatorStaggerMs = Math.max(0, Number(process.env.OPERATOR_STAGGER_SECONDS || 7)) * 1000
const operatorMatchJitterMs = Math.max(0, Number(process.env.PER_TOURNAMENT_OPERATOR_MATCH_JITTER_SECONDS || 10)) * 1000
const liveScoreBrowserViewers = Math.max(0, Number(process.env.PER_TOURNAMENT_LIVE_SCORE_BROWSER_VIEWERS || 1))
const browserDomMaxP95Ms = Math.max(1, Number(process.env.BROWSER_DOM_MAX_P95_MS || 250))
const browserDeliveryMaxP95Ms = Math.max(1, Number(process.env.BROWSER_DELIVERY_MAX_P95_MS || 1000))
const actionTimeoutMs = Math.max(1000, Number(process.env.BROWSER_ACTION_TIMEOUT_SECONDS || 120) * 1000)
const preparedMarker = "/loadtests/run-state/prepared"
const pendingScoreUpdates = new Map()
let scoreUpdateSequence = 0

const matchEventSequence = [
  { participant: "w1", action: "takedown_3" },
  { participant: "w1", action: "nearfall_2" },
  { participant: "w2", action: "escape_1" },
  { participant: "w1", action: "takedown_3" },
  { participant: "w1", action: "nearfall_2" },
  { participant: "w2", action: "reversal_2" }
]

const sleep = (milliseconds) => new Promise((resolve) => setTimeout(resolve, milliseconds))

function remainingMs(deadline) {
  return Math.max(0, deadline - Date.now())
}

function waitTimeout(deadline) {
  return Math.min(actionTimeoutMs, Math.max(1000, remainingMs(deadline)))
}

function configureContextTimeouts(context) {
  context.setDefaultTimeout(actionTimeoutMs)
  context.setDefaultNavigationTimeout(actionTimeoutMs)
}

async function waitForPreparation() {
  const expected = tournamentIds.join(",")
  while (true) {
    try {
      const preparedTournaments = (await fs.readFile(preparedMarker, "utf8")).trim()
      if (preparedTournaments === expected) return
    } catch (_error) {
    }
    await sleep(500)
  }
}

async function logIn(page, deadline) {
  await page.goto(`${baseUrl}/login`, { waitUntil: "domcontentloaded", timeout: waitTimeout(deadline) })
  await page.locator("#session_email").fill(email)
  await page.locator("#session_password").fill(password)
  await Promise.all([
    page.waitForURL(`${baseUrl}/`, { timeout: waitTimeout(deadline) }),
    page.getByRole("button", { name: "Log in" }).click()
  ])
}

async function discoverMatIds(page, deadline) {
  const matIdsByTournament = {}

  for (const tournamentId of tournamentIds) {
    matIdsByTournament[tournamentId] = {}
    await page.goto(`${baseUrl}/tournaments/${tournamentId}`, { waitUntil: "domcontentloaded", timeout: waitTimeout(deadline) })

    for (const matNumber of [1, 2, 3, 4, 5]) {
      const link = page.getByRole("link", { name: `Mat Load Test ${matNumber}`, exact: true })
      const href = await link.getAttribute("href")
      const match = href && href.match(/^\/mats\/(\d+)$/)
      if (!match) throw new Error(`Could not find Load Test mat ${matNumber} on tournament ${tournamentId}`)
      matIdsByTournament[tournamentId][matNumber] = match[1]
    }
  }

  return matIdsByTournament
}

async function prepareSession(browser, deadline) {
  const context = await browser.newContext()
  configureContextTimeouts(context)
  const page = await context.newPage()

  try {
    await logIn(page, deadline)
    const matIdsByTournament = await discoverMatIds(page, deadline)
    const storageState = await context.storageState()
    return { storageState, matIdsByTournament }
  } finally {
    await context.close()
  }
}

function randomizedMatchDurationMs() {
  if (operatorMatchJitterMs === 0) return matchDurationMs
  const offset = (Math.random() * 2 - 1) * operatorMatchJitterMs
  return Math.max(2000, matchDurationMs + offset)
}

async function clickMatchEvent(state, event) {
  const button = state.locator(`[data-participant-key='${event.participant}'][data-action-key='${event.action}']`)
  if (!(await button.isVisible())) return false

  await button.click()
  return true
}

async function openMatState(page, matId, deadline) {
  const matStatePath = `/mats/${matId}/state`
  if (!new URL(page.url()).pathname.endsWith(matStatePath)) {
    await page.goto(`${baseUrl}${matStatePath}`, { waitUntil: "domcontentloaded", timeout: waitTimeout(deadline) })
  }
}

async function syncWinTypeWithScores(page) {
  await page.evaluate(() => {
    const winTypeSelect = document.querySelector("[data-match-score-target='winType']")
    const winnerSelect = document.querySelector("[data-match-score-target='winnerSelect']")
    if (!winTypeSelect || !winnerSelect?.value) return

    const winnerScoreInput = document.querySelector("#winner-score")
    const loserScoreInput = document.querySelector("#loser-score")
    if (!winnerScoreInput || !loserScoreInput) return

    const winnerScore = parseInt(winnerScoreInput.value || "0", 10)
    const loserScore = parseInt(loserScoreInput.value || "0", 10)
    if (winnerScore <= loserScore) return

    const scoreDifference = winnerScore - loserScore
    let expectedWinType = "Decision"
    if (scoreDifference >= 15) expectedWinType = "Tech Fall"
    else if (scoreDifference >= 8) expectedWinType = "Major"

    if (winTypeSelect.value !== expectedWinType) {
      winTypeSelect.value = expectedWinType
      winTypeSelect.dispatchEvent(new Event("change", { bubbles: true }))
    }
  })
}

async function waitForSubmitReady(page, deadline) {
  const timeout = waitTimeout(deadline)
  await page.waitForFunction(() => {
    const winnerSelect = document.querySelector("[data-match-score-target='winnerSelect']")
    return Boolean(winnerSelect?.value)
  }, null, { timeout })
  await syncWinTypeWithScores(page)
  await page.waitForFunction(
    () => !document.querySelector("#update-match-btn")?.disabled,
    null,
    { timeout }
  )
}

async function waitForNextMatch(page, previousMatchId, deadline) {
  await page.waitForFunction(
    (priorMatchId) => {
      const matchState = document.querySelector("[data-controller~='match-state']")
      const scoreForm = document.querySelector("[data-controller~='match-score']")
      if (!matchState || !scoreForm) return false

      const currentMatchId = matchState.getAttribute("data-match-state-match-id-value")
      const finished = scoreForm.getAttribute("data-match-score-finished-value") === "true"
      return Boolean(currentMatchId && currentMatchId !== priorMatchId && !finished)
    },
    previousMatchId,
    { timeout: waitTimeout(deadline) }
  )
  await page.locator("[data-action='click->match-state#startClock']").waitFor({ state: "visible", timeout: waitTimeout(deadline) })
}

async function runMatch(page, matId, deadline) {
  if (remainingMs(deadline) < 5000) return false

  await openMatState(page, matId, deadline)

  const state = page.locator("[data-controller~='match-state']")
  if (await state.count() === 0) {
    await sleep(1000)
    return false
  }

  const currentMatchId = await state.getAttribute("data-match-state-match-id-value")
  const currentMatchDurationMs = randomizedMatchDurationMs()
  await state.locator("[data-action='click->match-state#startClock']").waitFor({ state: "visible", timeout: waitTimeout(deadline) })
  await sleep(Math.min(clockStartDelayMs, remainingMs(deadline)))
  if (Date.now() >= deadline) return false

  await state.locator("[data-action='click->match-state#startClock']").click()
  const matchStartTime = Date.now()
  const matchEndTime = matchStartTime + currentMatchDurationMs
  let eventIndex = 0
  let recordedDeliveryMetric = false

  while (Date.now() < matchEndTime && Date.now() < deadline) {
    const nextEventTime = matchStartTime + (eventIndex + 1) * eventIntervalMs
    const waitMs = nextEventTime - Date.now()
    if (waitMs > 0) {
      await sleep(Math.min(waitMs, remainingMs(deadline)))
    }
    if (Date.now() >= matchEndTime || Date.now() >= deadline) break

    const event = matchEventSequence[eventIndex % matchEventSequence.length]
    if (await clickMatchEvent(state, event)) {
      if (!recordedDeliveryMetric) {
        const matchId = await state.getAttribute("data-match-state-match-id-value")
        pendingScoreUpdates.set(matchId, { sequence: ++scoreUpdateSequence, startedAtMs: Date.now() })
        recordedDeliveryMetric = true
      }
    }
    eventIndex += 1
  }

  if (Date.now() >= deadline) return false

  await state.locator("[data-action='click->match-state#stopClock']").click()
  const submitButton = page.locator("#update-match-btn")
  await submitButton.waitFor({ state: "visible", timeout: waitTimeout(deadline) })
  await waitForSubmitReady(page, deadline)

  page.once("dialog", (dialog) => dialog.accept())
  await submitButton.click()
  await waitForNextMatch(page, currentMatchId, deadline)
  return true
}

async function runOperator(browser, storageState, tournamentId, matNumber, matIndex, matId, deadline) {
  const context = await browser.newContext({ storageState })
  configureContextTimeouts(context)
  const page = await context.newPage()
  const operatorLabel = `tournament ${tournamentId} mat ${matNumber}`

  try {
    await sleep(matIndex * operatorStaggerMs)
    let completedMatches = 0
    console.log(`[operator ${operatorLabel}] controlling mat ${matId}`)

    while (Date.now() < deadline) {
      try {
        if (await runMatch(page, matId, deadline)) {
          completedMatches += 1
          console.log(`[operator ${operatorLabel}] submitted match ${completedMatches}`)
        }
      } catch (error) {
        console.error(`[operator ${operatorLabel}] ${error.message}`)
        await sleep(1000)
      }
    }

    if (completedMatches === 0) {
      throw new Error(`Operator ${operatorLabel} did not complete a match`)
    }
  } finally {
    await context.close()
  }
}

async function runLiveScoreBrowserViewer(browser, tournamentId, viewerNumber, deadline) {
  const context = await browser.newContext()
  configureContextTimeouts(context)
  const page = await context.newPage()
  const deliveryMetrics = { frame: [], paint: [] }
  const measuredSequences = new Set()

  try {
    await page.exposeFunction("recordLiveScoreDelivery", ({ matchId, receivedAtMs, paintedAtMs }) => {
      const pending = pendingScoreUpdates.get(String(matchId))
      if (!pending || measuredSequences.has(pending.sequence)) return

      measuredSequences.add(pending.sequence)
      deliveryMetrics.frame.push(receivedAtMs - pending.startedAtMs)
      deliveryMetrics.paint.push(paintedAtMs - pending.startedAtMs)
    })
    await page.goto(`${baseUrl}/tournaments/${tournamentId}/live_scores`, { waitUntil: "domcontentloaded", timeout: waitTimeout(deadline) })
    await page.waitForFunction(
      () => window.App?.cable?.connection?.webSocket?.readyState === WebSocket.OPEN,
      null,
      { timeout: waitTimeout(deadline) }
    )
    await page.evaluate(() => {
      const socket = window.App.cable.connection.webSocket
      const originalOnMessage = socket.onmessage
      window.__liveScoreDomLatencies = []
      window.__liveScoreMessageHandlerLatencies = []

      socket.onmessage = function instrumentLiveScoreMessage(event) {
        const isApplicationMessage = typeof event.data === "string" && event.data.includes('"message"')
        if (!isApplicationMessage) return originalOnMessage.call(this, event)

        let deliveredMatchId = null
        try {
          const frame = JSON.parse(event.data)
          const identifier = JSON.parse(frame.identifier || "{}")
          const message = frame.message || {}
          if (
            identifier.channel === "MatchChannel" &&
            (Object.hasOwn(message, "w1_stat") || Object.hasOwn(message, "w2_stat"))
          ) {
            deliveredMatchId = String(identifier.match_id)
          }
        } catch (_error) {
        }

        const cards = Array.from(document.querySelectorAll("[data-controller~='match-scoreboard']"))
        const before = cards.map((card) => card.textContent).join("\n")
        const startedAt = performance.now()
        const receivedAtMs = Date.now()
        const result = originalOnMessage.call(this, event)
        const handledAt = performance.now()
        const after = cards.map((card) => card.textContent).join("\n")
        window.__liveScoreMessageHandlerLatencies.push(handledAt - startedAt)

        if (before !== after || deliveredMatchId) {
          requestAnimationFrame(() => {
            if (before !== after) {
              window.__liveScoreDomLatencies.push(performance.now() - startedAt)
            }
            if (deliveredMatchId) {
              window.recordLiveScoreDelivery({
                matchId: deliveredMatchId,
                receivedAtMs,
                paintedAtMs: Date.now()
              })
            }
          })
        }
        return result
      }
    })

    await sleep(Math.max(0, deadline - Date.now()))
    await sleep(100)
    const metrics = await page.evaluate(() => ({
      dom: window.__liveScoreDomLatencies || [],
      handler: window.__liveScoreMessageHandlerLatencies || []
    }))
    console.log(`[live-score viewer ${viewerNumber} tournament ${tournamentId}] observed ${metrics.handler.length} application messages and ${metrics.dom.length} DOM updates`)
    return { ...metrics, delivery: deliveryMetrics }
  } finally {
    await context.close()
  }
}

function percentile(values, percentage) {
  if (values.length === 0) return null
  const sorted = [...values].sort((left, right) => left - right)
  return sorted[Math.ceil((percentage / 100) * sorted.length) - 1]
}

function metricSummary(values) {
  return {
    p50: percentile(values, 50),
    p95: percentile(values, 95),
    max: values.length ? Math.max(...values) : null
  }
}

async function writeLiveScoreBrowserReport(metrics) {
  const dom = metrics.flatMap((measurement) => measurement.dom)
  const handler = metrics.flatMap((measurement) => measurement.handler)
  const deliveryFrame = metrics.flatMap((measurement) => measurement.delivery.frame)
  const deliveryPaint = metrics.flatMap((measurement) => measurement.delivery.paint)
  const summary = {
    tournamentCount,
    browserViewers: metrics.length,
    applicationMessages: handler.length,
    domUpdates: dom.length,
    scoreUpdatesObserved: deliveryFrame.length,
    messageHandlerMs: metricSummary(handler),
    websocketToDomPaintMs: metricSummary(dom),
    operatorActionToBrowserFrameMs: metricSummary(deliveryFrame),
    operatorActionToDomPaintMs: metricSummary(deliveryPaint)
  }

  await fs.mkdir("/loadtests/results", { recursive: true })
  await fs.writeFile("/loadtests/results/live-score-browser-metrics.json", `${JSON.stringify(summary, null, 2)}\n`)
  console.log(`[live-score browser metrics] ${JSON.stringify(summary)}`)

  if (metrics.length > 0 && (handler.length === 0 || dom.length === 0 || deliveryFrame.length === 0)) {
    throw new Error("Live-score browser viewers did not observe websocket-driven DOM updates")
  }
  if (summary.websocketToDomPaintMs.p95 > browserDomMaxP95Ms) {
    throw new Error(`Live-score browser DOM p95 ${summary.websocketToDomPaintMs.p95}ms exceeded ${browserDomMaxP95Ms}ms`)
  }
  if (summary.operatorActionToDomPaintMs.p95 > browserDeliveryMaxP95Ms) {
    throw new Error(`Live-score delivery p95 ${summary.operatorActionToDomPaintMs.p95}ms exceeded ${browserDeliveryMaxP95Ms}ms`)
  }
}

function reportRejectedRuns(label, results) {
  const failures = results.filter((result) => result.status === "rejected")
  for (const failure of failures) {
    console.error(`[${label}] ${failure.reason}`)
  }
  return failures.length
}

async function main() {
  await waitForPreparation()
  const deadline = Date.now() + testDurationMs
  const browser = await chromium.launch({ headless: process.env.HEADLESS !== "false" })

  try {
    const { storageState, matIdsByTournament } = await prepareSession(browser, deadline)
    const operatorRuns = tournamentIds.flatMap((tournamentId) =>
      [1, 2, 3, 4, 5].map((matNumber, matIndex) =>
        runOperator(
          browser,
          storageState,
          tournamentId,
          matNumber,
          matIndex,
          matIdsByTournament[tournamentId][matNumber],
          deadline
        )
      )
    )
    const viewerRuns = tournamentIds.flatMap((tournamentId) =>
      Array.from({ length: liveScoreBrowserViewers }, (_, index) =>
        runLiveScoreBrowserViewer(browser, tournamentId, index + 1, deadline)
      )
    )
    const settled = await Promise.allSettled([...operatorRuns, ...viewerRuns])
    const operatorResults = settled.slice(0, operatorRuns.length)
    const viewerResults = settled.slice(operatorRuns.length)
    const operatorFailures = reportRejectedRuns("operator failure", operatorResults)
    const viewerFailures = reportRejectedRuns("live-score viewer failure", viewerResults)

    if (viewerFailures === 0) {
      const viewerMetrics = viewerResults
        .filter((result) => result.status === "fulfilled")
        .map((result) => result.value)
      await writeLiveScoreBrowserReport(viewerMetrics)
    }

    if (operatorFailures > 0) {
      throw new Error(`${operatorFailures} of ${operatorRuns.length} operators did not complete a match`)
    }
    if (viewerFailures > 0) {
      throw new Error(`${viewerFailures} of ${viewerRuns.length} live-score browser viewers failed`)
    }
  } finally {
    await browser.close()
  }
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
