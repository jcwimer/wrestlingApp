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
    controller.syncRound = vi.fn()
    controller.drawConnections = vi.fn()

    controller.activate(secondTab)

    expect(firstPanel.hidden).toBe(true)
    expect(secondPanel.hidden).toBe(false)
    expect(firstTab.setAttribute).toHaveBeenCalledWith("aria-selected", false)
    expect(secondTab.setAttribute).toHaveBeenCalledWith("aria-selected", true)
    expect(secondTab.tabIndex).toBe(0)
    expect(controller.drawConnections).toHaveBeenCalled()
  })

  it("scrolls to a selected round", () => {
    const controller = new BracketNavigationController()
    const rounds = [{ offsetLeft: 20 }, { offsetLeft: 240 }, { offsetLeft: 460 }]
    const viewport = { scrollTo: vi.fn() }
    controller.panelTargets = [{
      hidden: false,
      querySelectorAll: () => rounds,
      querySelector: () => viewport
    }]

    controller.goToRound({ currentTarget: { dataset: { roundIndex: "2" } } })

    expect(viewport.scrollTo).toHaveBeenCalledWith({ left: 440, behavior: "smooth" })
  })
})
