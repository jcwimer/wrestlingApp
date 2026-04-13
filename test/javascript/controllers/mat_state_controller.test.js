import { beforeEach, describe, expect, it, vi } from "vitest"
import MatStateController from "../../../app/assets/javascripts/controllers/mat_state_controller.js"
import { SHORT_LIVED_TTL_MS } from "match-state-transport"

class FakeFormElement {}

function buildController() {
  const controller = new MatStateController()
  controller.element = {
    addEventListener: vi.fn(),
    removeEventListener: vi.fn()
  }
  controller.tournamentIdValue = 8
  controller.matIdValue = 3
  controller.boutNumberValue = 1001
  controller.matchIdValue = 22
  controller.selectMatchUrlValue = "/mats/3/select_match"
  controller.hasSelectMatchUrlValue = true
  controller.hasWeightLabelValue = true
  controller.weightLabelValue = "106"
  controller.w1IdValue = 11
  controller.w2IdValue = 12
  controller.w1NameValue = "Alpha"
  controller.w2NameValue = "Bravo"
  controller.w1SchoolValue = "School A"
  controller.w2SchoolValue = "School B"
  return controller
}

describe("mat state controller", () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    vi.spyOn(Date, "now").mockReturnValue(1_000)
    global.HTMLFormElement = FakeFormElement
    global.window = {
      localStorage: {
        setItem: vi.fn(),
        getItem: vi.fn(() => ""),
        removeItem: vi.fn()
      }
    }
    global.document = {
      querySelector: vi.fn(() => ({ content: "csrf-token" }))
    }
    global.fetch = vi.fn(() => Promise.resolve())
  })

  it("connect saves and broadcasts the selected bout and binds submit handling", () => {
    const controller = buildController()
    controller.saveSelectedBout = vi.fn()
    controller.broadcastSelectedBout = vi.fn()

    controller.connect()

    expect(controller.saveSelectedBout).toHaveBeenCalledTimes(1)
    expect(controller.broadcastSelectedBout).toHaveBeenCalledTimes(1)
    expect(controller.element.addEventListener).toHaveBeenCalledWith("submit", controller.boundHandleSubmit)
  })

  it("saves the selected bout in tournament-scoped localStorage", () => {
    const controller = buildController()

    controller.saveSelectedBout()

    expect(window.localStorage.setItem).toHaveBeenCalledTimes(1)
    const [key, value] = window.localStorage.setItem.mock.calls[0]
    expect(key).toBe("mat-selected-bout:8:3")
    const parsedValue = JSON.parse(value)
    expect(parsedValue.expiresAt).toBe(1_000 + SHORT_LIVED_TTL_MS)
    expect(parsedValue.value).toMatchObject({
      boutNumber: 1001,
      matchId: 22
    })
  })

  it("broadcasts the selected bout with the last saved result", () => {
    const controller = buildController()
    controller.loadLastMatchResult = vi.fn(() => "Last result")

    controller.broadcastSelectedBout()

    expect(fetch).toHaveBeenCalledTimes(1)
    const [url, options] = fetch.mock.calls[0]
    expect(url).toBe("/mats/3/select_match")
    expect(options.method).toBe("POST")
    expect(options.body.get("match_id")).toBe("22")
    expect(options.body.get("bout_number")).toBe("1001")
    expect(options.body.get("last_match_result")).toBe("Last result")
  })

  it("builds the last match result string from the results form", () => {
    const controller = buildController()
    const values = {
      "#match_winner_id": "11",
      "#match_win_type": "Pin",
      "#final-score-field": "01:09"
    }
    const form = new FakeFormElement()
    form.querySelector = vi.fn((selector) => ({ value: values[selector] }))

    expect(controller.buildLastMatchResult(form)).toBe(
      "106 lbs - Alpha (School A) Pin Bravo (School B) 01:09"
    )
  })

  it("handleSubmit saves and broadcasts the last match result", () => {
    const controller = buildController()
    const form = new FakeFormElement()
    controller.buildLastMatchResult = vi.fn(() => "Result text")
    controller.saveLastMatchResult = vi.fn()
    controller.broadcastCurrentState = vi.fn()

    controller.handleSubmit({ target: form })

    expect(controller.saveLastMatchResult).toHaveBeenCalledWith("Result text")
    expect(controller.broadcastCurrentState).toHaveBeenCalledWith("Result text")
  })

  it("broadcastCurrentState posts the selected match and latest result", () => {
    const controller = buildController()

    controller.broadcastCurrentState("Result text")

    expect(fetch).toHaveBeenCalledTimes(1)
    const [url, options] = fetch.mock.calls[0]
    expect(url).toBe("/mats/3/select_match")
    expect(options.keepalive).toBe(true)
    expect(options.body.get("match_id")).toBe("22")
    expect(options.body.get("bout_number")).toBe("1001")
    expect(options.body.get("last_match_result")).toBe("Result text")
  })

  it("does not write selected bout storage without a mat id", () => {
    const controller = buildController()
    controller.matIdValue = 0

    controller.saveSelectedBout()

    expect(window.localStorage.setItem).not.toHaveBeenCalled()
  })

  it("does not broadcast selected bout without a select-match url", () => {
    const controller = buildController()
    controller.hasSelectMatchUrlValue = false
    controller.selectMatchUrlValue = ""

    controller.broadcastSelectedBout()

    expect(fetch).not.toHaveBeenCalled()
  })

  it("saves and clears the last match result in localStorage", () => {
    const controller = buildController()

    controller.saveLastMatchResult("Result text")
    const [key, value] = window.localStorage.setItem.mock.calls[0]
    expect(key).toBe("mat-last-match-result:8:3")
    expect(JSON.parse(value)).toMatchObject({
      expiresAt: 1_000 + SHORT_LIVED_TTL_MS,
      value: "Result text"
    })

    controller.saveLastMatchResult("")
    expect(window.localStorage.removeItem).toHaveBeenCalledWith("mat-last-match-result:8:3")
  })

  it("returns blank last match result when required form values are missing or unknown", () => {
    const controller = buildController()
    const form = new FakeFormElement()
    form.querySelector = vi.fn((selector) => {
      if (selector === "#match_winner_id") return { value: "" }
      if (selector === "#match_win_type") return { value: "Pin" }
      return { value: "01:09" }
    })

    expect(controller.buildLastMatchResult(form)).toBe("")

    form.querySelector = vi.fn((selector) => {
      if (selector === "#match_winner_id") return { value: "999" }
      if (selector === "#match_win_type") return { value: "Pin" }
      return { value: "01:09" }
    })

    expect(controller.buildLastMatchResult(form)).toBe("")
  })
})
