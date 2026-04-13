import { beforeEach, describe, expect, it, vi } from "vitest"
import MatchScoreController from "../../../app/assets/javascripts/controllers/match_score_controller.js"

class FakeNode {
  constructor(tagName = "div") {
    this.tagName = tagName
    this.children = []
    this.value = ""
    this.innerHTML = ""
    this.innerText = ""
    this.id = ""
    this.placeholder = ""
    this.type = ""
    this.style = {}
    this.listeners = {}
    this.classList = {
      add: vi.fn(),
      remove: vi.fn()
    }
  }

  appendChild(child) {
    this.children.push(child)
    return child
  }

  setAttribute(name, value) {
    this[name] = value
  }

  addEventListener(eventName, callback) {
    this.listeners[eventName] = callback
  }

  querySelector(selector) {
    if (selector === "input") return this.allInputs()[0] || null
    if (!selector.startsWith("#")) return null
    return this.findById(selector.slice(1))
  }

  querySelectorAll(selector) {
    if (selector !== "input") return []
    return this.allInputs()
  }

  findById(id) {
    if (this.id === id) return this
    for (const child of this.children) {
      const match = child.findById?.(id)
      if (match) return match
    }
    return null
  }

  allInputs() {
    const matches = this.tagName === "input" ? [this] : []
    for (const child of this.children) {
      matches.push(...(child.allInputs?.() || []))
    }
    return matches
  }
}

function buildController() {
  const controller = new MatchScoreController()
  controller.element = {
    addEventListener: vi.fn(),
    removeEventListener: vi.fn()
  }
  controller.winTypeTarget = { value: "Decision" }
  controller.winnerSelectTarget = { value: "", options: [{ value: "" }, { value: "11" }], selectedIndex: 1 }
  controller.overtimeSelectTarget = { value: "", options: [{ value: "" }, { value: "SV-1" }] }
  controller.submitButtonTarget = { disabled: false }
  controller.dynamicScoreInputTarget = new FakeNode("div")
  controller.finalScoreFieldTarget = { value: "" }
  controller.validationAlertsTarget = {
    innerHTML: "",
    style: {},
    classList: { add: vi.fn(), remove: vi.fn() }
  }
  controller.pinTimeTipTarget = { style: {} }
  controller.manualOverrideValue = false
  controller.finishedValue = false
  controller.winnerScoreValue = "0"
  controller.loserScoreValue = "0"
  controller.pinMinutesValue = "0"
  controller.pinSecondsValue = "00"
  controller.hasWinnerSelectTarget = true
  controller.hasOvertimeSelectTarget = true
  return controller
}

describe("match score controller", () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    global.document = {
      createElement: vi.fn((tagName) => new FakeNode(tagName))
    }
  })

  it("connect binds manual-override listeners and initializes unfinished forms", () => {
    const controller = buildController()
    controller.updateScoreInput = vi.fn()
    controller.validateForm = vi.fn()
    vi.spyOn(globalThis, "setTimeout").mockImplementation((fn) => {
      fn()
      return 1
    })

    controller.connect()

    expect(controller.element.addEventListener).toHaveBeenCalledWith("input", controller.boundMarkManualOverride)
    expect(controller.element.addEventListener).toHaveBeenCalledWith("change", controller.boundMarkManualOverride)
    expect(controller.updateScoreInput).toHaveBeenCalledTimes(1)
    expect(controller.validateForm).toHaveBeenCalledTimes(1)
  })

  it("connect skips score initialization for finished forms", () => {
    const controller = buildController()
    controller.finishedValue = true
    controller.updateScoreInput = vi.fn()
    controller.validateForm = vi.fn()

    controller.connect()

    expect(controller.updateScoreInput).not.toHaveBeenCalled()
    expect(controller.validateForm).toHaveBeenCalledTimes(1)
  })

  it("applyDefaultResults fills derived defaults until the user overrides them", () => {
    const controller = buildController()
    controller.updateScoreInput = vi.fn()
    controller.validateForm = vi.fn()

    controller.applyDefaultResults({
      winnerId: 11,
      overtimeType: "SV-1",
      winnerScore: 5,
      loserScore: 2,
      pinMinutes: 1,
      pinSeconds: 9
    })

    expect(controller.winnerSelectTarget.value).toBe("11")
    expect(controller.overtimeSelectTarget.value).toBe("SV-1")
    expect(controller.winnerScoreValue).toBe("5")
    expect(controller.loserScoreValue).toBe("2")
    expect(controller.pinMinutesValue).toBe("1")
    expect(controller.pinSecondsValue).toBe("09")
    expect(controller.updateScoreInput).toHaveBeenCalledTimes(1)
    expect(controller.validateForm).toHaveBeenCalledTimes(1)
  })

  it("applyDefaultResults does nothing after manual override", () => {
    const controller = buildController()
    controller.manualOverrideValue = true
    controller.updateScoreInput = vi.fn()

    controller.applyDefaultResults({ winnerId: 11, winnerScore: 5 })

    expect(controller.winnerSelectTarget.value).toBe("")
    expect(controller.updateScoreInput).not.toHaveBeenCalled()
  })

  it("markManualOverride only reacts to trusted events", () => {
    const controller = buildController()

    controller.markManualOverride({ isTrusted: false })
    expect(controller.manualOverrideValue).toBe(false)

    controller.markManualOverride({ isTrusted: true })
    expect(controller.manualOverrideValue).toBe(true)
  })

  it("validateForm disables submit for invalid decision scores and enables it for valid ones", () => {
    const controller = buildController()
    controller.winTypeTarget.value = "Decision"
    controller.winnerSelectTarget.value = "11"
    controller.winnerScoreValue = "2"
    controller.loserScoreValue = "3"

    expect(controller.validateForm()).toBe(false)
    expect(controller.submitButtonTarget.disabled).toBe(true)
    expect(controller.validationAlertsTarget.style.display).toBe("block")

    controller.winnerScoreValue = "5"
    controller.loserScoreValue = "2"
    controller.validationAlertsTarget.style = {}

    expect(controller.validateForm()).toBe(true)
    expect(controller.submitButtonTarget.disabled).toBe(false)
  })

  it("winnerChanged and winTypeChanged revalidate the form", () => {
    const controller = buildController()
    controller.updateScoreInput = vi.fn()
    controller.validateForm = vi.fn()

    controller.winTypeChanged()
    expect(controller.updateScoreInput).toHaveBeenCalledTimes(1)
    expect(controller.validateForm).toHaveBeenCalledTimes(1)

    controller.winnerChanged()
    expect(controller.validateForm).toHaveBeenCalledTimes(2)
  })

  it("updateScoreInput builds pin inputs and writes pin time score", () => {
    const controller = buildController()
    controller.winTypeTarget.value = "Pin"
    controller.pinMinutesValue = "1"
    controller.pinSecondsValue = "09"
    controller.validateForm = vi.fn()

    controller.updateScoreInput()

    expect(controller.pinTimeTipTarget.style.display).toBe("block")
    expect(controller.dynamicScoreInputTarget.querySelector("#minutes").value).toBe("1")
    expect(controller.dynamicScoreInputTarget.querySelector("#seconds").value).toBe("09")
    expect(controller.finalScoreFieldTarget.value).toBe("01:09")
  })

  it("updateScoreInput builds point inputs and writes point score", () => {
    const controller = buildController()
    controller.winTypeTarget.value = "Decision"
    controller.winnerScoreValue = "7"
    controller.loserScoreValue = "3"
    controller.validateForm = vi.fn()

    controller.updateScoreInput()

    expect(controller.pinTimeTipTarget.style.display).toBe("none")
    expect(controller.dynamicScoreInputTarget.querySelector("#winner-score").value).toBe("7")
    expect(controller.dynamicScoreInputTarget.querySelector("#loser-score").value).toBe("3")
    expect(controller.finalScoreFieldTarget.value).toBe("7-3")
  })

  it("updateScoreInput clears score for non-score win types", () => {
    const controller = buildController()
    controller.winTypeTarget.value = "Forfeit"
    controller.finalScoreFieldTarget.value = "7-3"
    controller.validateForm = vi.fn()

    controller.updateScoreInput()

    expect(controller.pinTimeTipTarget.style.display).toBe("none")
    expect(controller.finalScoreFieldTarget.value).toBe("")
    expect(controller.dynamicScoreInputTarget.children.at(-1).innerText).toBe("No score required for Forfeit win type.")
  })

  it("validateForm enforces major and tech fall score boundaries", () => {
    const controller = buildController()
    controller.winnerSelectTarget.value = "11"
    controller.winTypeTarget.value = "Decision"
    controller.winnerScoreValue = "10"
    controller.loserScoreValue = "2"

    expect(controller.validateForm()).toBe(false)
    expect(controller.validationAlertsTarget.innerHTML).toContain("Major")

    controller.winTypeTarget.value = "Tech Fall"
    controller.winnerScoreValue = "17"
    controller.loserScoreValue = "2"
    controller.validationAlertsTarget.innerHTML = ""
    controller.validationAlertsTarget.style = {}

    expect(controller.validateForm()).toBe(true)
    expect(controller.submitButtonTarget.disabled).toBe(false)
  })
})
