import fs from "node:fs"
import vm from "node:vm"
import { describe, expect, it, vi } from "vitest"

function loadHarness() {
  const files = { readFile: vi.fn().mockResolvedValue("205"), mkdir: vi.fn(), writeFile: vi.fn() }
  const browser = { close: vi.fn() }
  const source = fs.readFileSync(new URL("../../loadtests/browser-operators.js", import.meta.url), "utf8")
  const context = vm.createContext({
    require: (name) => name === "node:fs/promises" ? files : { chromium: { launch: async () => browser } },
    process: { env: { PER_TOURNAMENT_LIVE_SCORE_BROWSER_VIEWERS: "0" } },
    console: { log: vi.fn(), error: vi.fn() },
    URL,
    setTimeout
  })
  vm.runInContext(source.slice(0, source.lastIndexOf("main().catch")), context)
  return { context, files, browser }
}

describe("browser load-test scoring failures", () => {
  it.each([303, 422])("records the submission HTTP %s response and rejects errors immediately", async (status) => {
    const { context } = loadHarness()
    const action = "http://localhost/matches/10"
    const response = { url: () => action, request: () => ({ method: () => "POST" }), status: () => status }
    const page = {
      once: vi.fn(),
      waitForResponse: vi.fn(async (predicate) => {
        expect(predicate({ ...response, request: () => ({ method: () => "GET" }) })).toBe(false)
        expect(predicate({ ...response, url: () => `${action}/state` })).toBe(false)
        expect(predicate(response)).toBe(true)
        return response
      })
    }
    const button = { evaluate: async (callback) => callback({ form: { action } }), click: vi.fn() }
    const metrics = { submissionAttempts: 0, responseStatuses: {} }
    const submitted = context.submitMatch(page, button, Date.now() + 5000, metrics)
    if (status === 422) await expect(submitted).rejects.toThrow("HTTP 422")
    else await submitted
    expect(metrics).toEqual({ submissionAttempts: 1, responseStatuses: { [status]: 1 } })
    expect(button.click).toHaveBeenCalledOnce()
  })

  it("retains timeout failures after an operator recovers and completes a match", async () => {
    const { context } = loadHarness()
    const metrics = { completedMatches: 0, timeouts: 0, failures: [] }
    let now = 0
    let attempts = 0
    context.Date = { now: () => now }
    context.setTimeout = (callback) => callback()
    context.runMatch = async () => {
      attempts += 1
      if (attempts === 1) throw Object.assign(new Error("next-match timeout"), { name: "TimeoutError" })
      now = 10000
      return true
    }
    const page = { goto: vi.fn() }
    const browserContext = { setDefaultTimeout: vi.fn(), setDefaultNavigationTimeout: vi.fn(), newPage: async () => page, close: vi.fn() }
    await context.runOperator({ newContext: async () => browserContext }, {}, 205, 1, 0, "20", 10000, metrics)
    expect(metrics).toEqual({ completedMatches: 1, timeouts: 1, failures: ["next-match timeout"] })
    expect(page.goto).toHaveBeenCalledWith("about:blank")
  })

  it("writes operator results and fails the run even when every operator completed a match", async () => {
    const { context, files, browser } = loadHarness()
    context.prepareSession = async () => ({ storageState: {}, matIdsByTournament: { 205: {} } })
    context.runOperator = async (...args) => {
      const metrics = args.at(-1)
      metrics.completedMatches = 1
      metrics.failures.push("Match submission rejected with HTTP 422")
      metrics.responseStatuses[422] = 1
    }
    await expect(context.main()).rejects.toThrow("5 of 5 operators had scoring failures")
    const report = files.writeFile.mock.calls.find(([path]) => path.endsWith("browser-operator-metrics.json"))
    expect(JSON.parse(report[1])).toHaveLength(5)
    expect(JSON.parse(report[1])[0]).toMatchObject({ completedMatches: 1, responseStatuses: { 422: 1 } })
    expect(browser.close).toHaveBeenCalledOnce()
  })
})
