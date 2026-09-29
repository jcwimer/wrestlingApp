import { afterEach, describe, expect, it, vi } from "vitest"
import BracketNavigationController from "../../../app/assets/javascripts/controllers/bracket_navigation_controller.js"

function classList() {
  return { toggle: vi.fn() }
}

afterEach(() => {
  vi.unstubAllGlobals()
})

describe("bracket navigation", () => {
  it("switches sections with accessible tab state", () => {
    vi.stubGlobal("requestAnimationFrame", (callback) => callback())
    const controller = new BracketNavigationController()
    const firstTab = { dataset: { panel: "championship" }, setAttribute: vi.fn(), classList: classList() }
    const secondTab = { dataset: { panel: "consolation" }, setAttribute: vi.fn(), classList: classList() }
    const firstPanel = { dataset: { panel: "championship" }, hidden: false }
    const secondPanel = { dataset: { panel: "consolation" }, hidden: true }
    controller.tabTargets = [firstTab, secondTab]
    controller.panelTargets = [firstPanel, secondPanel]
    controller.drawConnections = vi.fn()

    controller.activate(secondTab)

    expect(firstPanel.hidden).toBe(true)
    expect(secondPanel.hidden).toBe(false)
    expect(firstTab.setAttribute).toHaveBeenCalledWith("aria-selected", false)
    expect(secondTab.setAttribute).toHaveBeenCalledWith("aria-selected", true)
    expect(secondTab.tabIndex).toBe(0)
    expect(controller.drawConnections).toHaveBeenCalled()
  })

  it("shows the selected round and following rounds, then restores earlier rounds", () => {
    vi.stubGlobal("requestAnimationFrame", (callback) => callback())
    const controller = new BracketNavigationController()
    const rounds = Array.from({ length: 4 }, () => ({ hidden: false }))
    const buttons = Array.from({ length: 4 }, () => ({ setAttribute: vi.fn(), classList: classList() }))
    const viewport = { scrollLeft: 240 }
    controller.panelTargets = [{
      hidden: false,
      dataset: {},
      querySelectorAll: (selector) => selector === ".interactive-bracket__round" ? rounds : buttons,
      querySelector: () => viewport
    }]
    controller.drawConnections = vi.fn()

    controller.goToRound({ currentTarget: { dataset: { roundIndex: "2" } } })

    expect(rounds.map((round) => round.hidden)).toEqual([true, true, false, false])
    expect(viewport.scrollLeft).toBe(0)
    expect(buttons[2].setAttribute).toHaveBeenCalledWith("aria-current", "step")
    expect(controller.drawConnections).toHaveBeenCalledTimes(1)

    controller.previousRound()
    expect(rounds.map((round) => round.hidden)).toEqual([true, false, false, false])

    controller.goToRound({ currentTarget: { dataset: { roundIndex: "0" } } })
    expect(rounds.every((round) => !round.hidden)).toBe(true)

    controller.nextRound()
    expect(rounds.map((round) => round.hidden)).toEqual([true, false, false, false])
  })
})
