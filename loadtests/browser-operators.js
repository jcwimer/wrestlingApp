const fs = require("node:fs/promises")
const { chromium } = require("playwright")

const baseUrl = (process.env.BASE_URL || "http://host.docker.internal:3000").replace(/\/+$/, "")
const tournamentId = process.env.TOURNAMENT_ID || "204"
const email = process.env.OPERATOR_EMAIL || "test@test.com"
const password = process.env.OPERATOR_PASSWORD || "password"
const testDurationMs = Number(process.env.TEST_DURATION_SECONDS || 600) * 1000
const matchDurationMs = Math.max(2, Number(process.env.OPERATOR_MATCH_SECONDS || 50)) * 1000
const operatorStaggerMs = Math.max(0, Number(process.env.OPERATOR_STAGGER_SECONDS || 7)) * 1000
const operatorMatchJitterMs = Math.max(0, Number(process.env.OPERATOR_MATCH_JITTER_SECONDS || 10)) * 1000
const liveScoreBrowserViewers = Math.max(0, Number(process.env.LIVE_SCORE_BROWSER_VIEWERS || 1))
const browserDomMaxP95Ms = Math.max(1, Number(process.env.BROWSER_DOM_MAX_P95_MS || 250))
const browserDeliveryMaxP95Ms = Math.max(1, Number(process.env.BROWSER_DELIVERY_MAX_P95_MS || 1000))
const preparedMarker = "/loadtests/run-state/prepared"
const pendingScoreUpdates = new Map()
let scoreUpdateSequence = 0

const sleep = (milliseconds) => new Promise((resolve) => setTimeout(resolve, milliseconds))

async function waitForPreparation() {
  while (true) {
    try {
      const preparedTournament = (await fs.readFile(preparedMarker, "utf8")).trim()
      if (preparedTournament === tournamentId) return
    } catch (_error) {
    }
    await sleep(500)
  }
}

async function logIn(page) {
  await page.goto(`${baseUrl}/login`, { waitUntil: "domcontentloaded" })
  await page.locator("#session_email").fill(email)
  await page.locator("#session_password").fill(password)
  await Promise.all([
    page.waitForURL(`${baseUrl}/`),
    page.getByRole("button", { name: "Log in" }).click()
  ])
}

async function findMatId(page, matNumber) {
  await page.goto(`${baseUrl}/tournaments/${tournamentId}`, { waitUntil: "domcontentloaded" })
  const link = page.getByRole("link", { name: `Mat Load Test ${matNumber}`, exact: true })
  const href = await link.getAttribute("href")
  const match = href && href.match(/^\/mats\/(\d+)$/)
  if (!match) throw new Error(`Could not find Load Test mat ${matNumber}`)
  return match[1]
}

function randomizedMatchDurationMs() {
  if (operatorMatchJitterMs === 0) return matchDurationMs
  const offset = (Math.random() * 2 - 1) * operatorMatchJitterMs
  return Math.max(2000, matchDurationMs + offset)
}

async function runMatch(page, matId, deadline) {
  await page.goto(`${baseUrl}/mats/${matId}/state`, { waitUntil: "domcontentloaded" })

  const state = page.locator("[data-controller~='match-state']")
  if (await state.count() === 0) {
    await sleep(1000)
    return false
  }

  const takedown = state.locator("[data-participant-key='w1'][data-action-key='takedown_3']")
  const currentMatchDurationMs = randomizedMatchDurationMs()
  await takedown.waitFor({ state: "visible" })
  await state.locator("[data-action='click->match-state#startClock']").click()
  await sleep(Math.min(currentMatchDurationMs / 2, Math.max(0, deadline - Date.now())))
  if (Date.now() >= deadline) return false

  const matchId = await state.getAttribute("data-match-state-match-id-value")
  pendingScoreUpdates.set(matchId, { sequence: ++scoreUpdateSequence, startedAtMs: Date.now() })
  await takedown.click()
  await sleep(Math.min(currentMatchDurationMs / 2, Math.max(0, deadline - Date.now())))
  if (Date.now() >= deadline) return false

  await state.locator("[data-action='click->match-state#stopClock']").click()
  await page.locator("#update-match-btn").waitFor({ state: "visible" })
  await page.waitForFunction(() => !document.querySelector("#update-match-btn")?.disabled)

  page.once("dialog", (dialog) => dialog.accept())
  await Promise.all([
    page.waitForNavigation({ waitUntil: "domcontentloaded" }),
    page.locator("#update-match-btn").click()
  ])
  return true
}

async function runOperator(browser, matNumber, deadline) {
  const context = await browser.newContext()
  const page = await context.newPage()

  try {
    await sleep((matNumber - 1) * operatorStaggerMs)
    await logIn(page)
    const matId = await findMatId(page, matNumber)
    let completedMatches = 0
    console.log(`[operator ${matNumber}] controlling mat ${matId}`)

    while (Date.now() < deadline) {
      try {
        if (await runMatch(page, matId, deadline)) {
          completedMatches += 1
          console.log(`[operator ${matNumber}] submitted match ${completedMatches}`)
        }
      } catch (error) {
        console.error(`[operator ${matNumber}] ${error.message}`)
        await sleep(1000)
      }
    }

    if (completedMatches === 0) {
      throw new Error(`Operator ${matNumber} did not complete a match`)
    }
  } finally {
    await context.close()
  }
}

async function runLiveScoreBrowserViewer(browser, viewerNumber, deadline) {
  const context = await browser.newContext()
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
    await page.goto(`${baseUrl}/tournaments/${tournamentId}/live_scores`, { waitUntil: "domcontentloaded" })
    await page.waitForFunction(() => window.App?.cable?.connection?.webSocket?.readyState === WebSocket.OPEN)
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
    console.log(`[live-score viewer ${viewerNumber}] observed ${metrics.handler.length} application messages and ${metrics.dom.length} DOM updates`)
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

async function main() {
  await waitForPreparation()
  const deadline = Date.now() + testDurationMs
  const browser = await chromium.launch({ headless: process.env.HEADLESS !== "false" })

  try {
    const operatorRuns = [1, 2, 3, 4, 5].map((matNumber) => runOperator(browser, matNumber, deadline))
    const viewerRuns = Array.from(
      { length: liveScoreBrowserViewers },
      (_, index) => runLiveScoreBrowserViewer(browser, index + 1, deadline)
    )
    const results = await Promise.all([...operatorRuns, ...viewerRuns])
    await writeLiveScoreBrowserReport(results.slice(operatorRuns.length))
  } finally {
    await browser.close()
  }
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
