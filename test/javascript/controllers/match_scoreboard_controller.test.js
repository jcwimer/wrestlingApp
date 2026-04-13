import { beforeEach, describe, expect, it, vi } from "vitest"
import MatchScoreboardController from "../../../app/assets/javascripts/controllers/match_scoreboard_controller.js"

function makeTarget() {
  return {
    textContent: "",
    innerHTML: "",
    style: {}
  }
}

function buildController() {
  const controller = new MatchScoreboardController()

  controller.sourceModeValue = "localstorage"
  controller.displayModeValue = "fullscreen"
  controller.initialBoutNumberValue = 1001
  controller.matchIdValue = 22
  controller.matIdValue = 3
  controller.tournamentIdValue = 8

  controller.hasRedSectionTarget = true
  controller.hasCenterSectionTarget = true
  controller.hasGreenSectionTarget = true
  controller.hasEmptyStateTarget = true
  controller.hasRedNameTarget = true
  controller.hasRedSchoolTarget = true
  controller.hasRedScoreTarget = true
  controller.hasRedTimerIndicatorTarget = true
  controller.hasGreenNameTarget = true
  controller.hasGreenSchoolTarget = true
  controller.hasGreenScoreTarget = true
  controller.hasGreenTimerIndicatorTarget = true
  controller.hasClockTarget = true
  controller.hasPeriodLabelTarget = true
  controller.hasWeightLabelTarget = true
  controller.hasBoutLabelTarget = true
  controller.hasTimerBannerTarget = true
  controller.hasTimerBannerLabelTarget = true
  controller.hasTimerBannerClockTarget = true
  controller.hasRedStatsTarget = true
  controller.hasGreenStatsTarget = true
  controller.hasLastMatchResultTarget = true

  controller.redSectionTarget = makeTarget()
  controller.centerSectionTarget = makeTarget()
  controller.greenSectionTarget = makeTarget()
  controller.emptyStateTarget = makeTarget()
  controller.redNameTarget = makeTarget()
  controller.redSchoolTarget = makeTarget()
  controller.redScoreTarget = makeTarget()
  controller.redTimerIndicatorTarget = makeTarget()
  controller.greenNameTarget = makeTarget()
  controller.greenSchoolTarget = makeTarget()
  controller.greenScoreTarget = makeTarget()
  controller.greenTimerIndicatorTarget = makeTarget()
  controller.clockTarget = makeTarget()
  controller.periodLabelTarget = makeTarget()
  controller.weightLabelTarget = makeTarget()
  controller.boutLabelTarget = makeTarget()
  controller.timerBannerTarget = makeTarget()
  controller.timerBannerLabelTarget = makeTarget()
  controller.timerBannerClockTarget = makeTarget()
  controller.redStatsTarget = makeTarget()
  controller.greenStatsTarget = makeTarget()
  controller.lastMatchResultTarget = makeTarget()

  return controller
}

describe("match scoreboard controller", () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    vi.spyOn(Date, "now").mockReturnValue(1_000)
    global.window = {
      localStorage: {
        getItem: vi.fn(() => null)
      },
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      setInterval: vi.fn(() => 123),
      clearInterval: vi.fn()
    }
  })

  it("connects in localstorage mode using the extracted connection plan", () => {
    const controller = buildController()
    controller.setupMatSubscription = vi.fn()
    controller.setupMatchSubscription = vi.fn()
    controller.loadSelectedBoutNumber = vi.fn()
    controller.loadStateFromLocalStorage = vi.fn()
    controller.render = vi.fn()

    controller.connect()

    expect(window.addEventListener).toHaveBeenCalledWith("storage", controller.storageListener)
    expect(controller.loadSelectedBoutNumber).toHaveBeenCalledTimes(1)
    expect(controller.loadStateFromLocalStorage).toHaveBeenCalledTimes(1)
    expect(controller.setupMatSubscription).toHaveBeenCalledTimes(1)
    expect(controller.setupMatchSubscription).not.toHaveBeenCalled()
    expect(controller.render).toHaveBeenCalledTimes(1)
  })

  it("connects with populated localStorage state before any timer snapshot exists", () => {
    const controller = buildController()
    const persistedState = {
      metadata: {
        boutNumber: 1001,
        ruleset: "folkstyle_usa",
        bracketPosition: "Bracket Round of 64",
        w1Name: "Alpha",
        w2Name: "Bravo"
      },
      assignment: { w1: "green", w2: "red" },
      participantScores: { w1: 0, w2: 0 },
      phaseIndex: 0,
      clocksByPhase: {
        period_1: { remainingSeconds: 120, running: false, startedAt: null }
      },
      timers: {
        w1: { blood: { remainingSeconds: 300, running: false, startedAt: null } },
        w2: { blood: { remainingSeconds: 300, running: false, startedAt: null } }
      }
    }

    window.localStorage.getItem = vi.fn((key) => {
      if (key === "match-state:8:1001") return JSON.stringify(persistedState)
      return null
    })
    controller.setupMatSubscription = vi.fn()

    expect(() => controller.connect()).not.toThrow()
    expect(controller.previousTimerSnapshot).toEqual({
      "w1:blood": false,
      "w2:blood": false
    })
    controller.disconnect()
  })

  it("renders populated scoreboard targets from state", () => {
    const controller = buildController()
    controller.currentBoutNumber = 1001
    controller.liveMatchData = { w1_stat: "T3", w2_stat: "E1" }
    controller.lastMatchResult = "Previous result"
    controller.state = {
      metadata: {
        ruleset: "folkstyle_usa",
        bracketPosition: "Bracket Round of 64",
        weightLabel: "106",
        w1Name: "Alpha",
        w2Name: "Bravo",
        w1School: "School A",
        w2School: "School B"
      },
      assignment: { w1: "green", w2: "red" },
      participantScores: { w1: 3, w2: 1 },
      phaseIndex: 0,
      clocksByPhase: {
        period_1: { remainingSeconds: 120, running: false, startedAt: null }
      },
      timers: { w1: {}, w2: {} }
    }
    controller.timerBannerState = null

    controller.render()

    expect(controller.emptyStateTarget.style.display).toBe("none")
    expect(controller.redNameTarget.textContent).toBe("Bravo")
    expect(controller.redSchoolTarget.textContent).toBe("School B")
    expect(controller.redScoreTarget.textContent).toBe("1")
    expect(controller.greenNameTarget.textContent).toBe("Alpha")
    expect(controller.greenSchoolTarget.textContent).toBe("School A")
    expect(controller.greenScoreTarget.textContent).toBe("3")
    expect(controller.clockTarget.textContent).toBe("2:00")
    expect(controller.periodLabelTarget.textContent).toBe("Period 1")
    expect(controller.weightLabelTarget.textContent).toBe("Weight 106")
    expect(controller.boutLabelTarget.textContent).toBe("Bout 1001")
    expect(controller.redStatsTarget.textContent).toBe("E1")
    expect(controller.greenStatsTarget.textContent).toBe("T3")
    expect(controller.lastMatchResultTarget.textContent).toBe("Previous result")
    expect(controller.redSectionTarget.style.background).toBe("#c91f1f")
    expect(controller.greenSectionTarget.style.background).toBe("#1cab2d")
  })

  it("renders empty scoreboard targets when there is no match state", () => {
    const controller = buildController()
    controller.currentBoutNumber = 1005
    controller.lastMatchResult = "Last result"
    controller.state = null

    controller.render()

    expect(controller.emptyStateTarget.style.display).toBe("block")
    expect(controller.redNameTarget.textContent).toBe("NO MATCH")
    expect(controller.greenNameTarget.textContent).toBe("NO MATCH")
    expect(controller.clockTarget.textContent).toBe("-")
    expect(controller.periodLabelTarget.textContent).toBe("No Match")
    expect(controller.boutLabelTarget.textContent).toBe("Bout 1005")
    expect(controller.lastMatchResultTarget.textContent).toBe("Last result")
    expect(controller.redSectionTarget.style.background).toBe("#000")
    expect(controller.greenSectionTarget.style.background).toBe("#000")
  })

  it("renders a visible timer banner when the match clock is not running", () => {
    const controller = buildController()
    controller.config = {
      phaseSequence: [{ key: "period_1", type: "period" }],
      timers: { blood: { label: "Blood", maxSeconds: 300 } }
    }
    controller.state = {
      phaseIndex: 0,
      metadata: { w1Name: "Alpha" },
      assignment: { w1: "green", w2: "red" },
      clocksByPhase: { period_1: { running: false, remainingSeconds: 120, startedAt: null } },
      timers: {
        w1: { blood: { running: true, remainingSeconds: 300, startedAt: 1_000 } },
        w2: {}
      }
    }
    controller.timerBannerState = { participantKey: "w1", timerKey: "blood", expiresAt: null }

    controller.renderTimerBanner()

    expect(controller.timerBannerTarget.style.display).toBe("block")
    expect(controller.timerBannerLabelTarget.textContent).toBe("Green Alpha Blood Running")
    expect(controller.timerBannerClockTarget.textContent).toBe("0:00")
  })

  it("hides an expiring timer banner when the main clock is running", () => {
    const controller = buildController()
    controller.config = {
      phaseSequence: [{ key: "period_1", type: "period" }],
      timers: { blood: { label: "Blood", maxSeconds: 300 } }
    }
    controller.state = {
      phaseIndex: 0,
      metadata: { w1Name: "Alpha" },
      assignment: { w1: "green", w2: "red" },
      clocksByPhase: { period_1: { running: true, remainingSeconds: 120, startedAt: 1_000 } },
      timers: {
        w1: { blood: { running: false, remainingSeconds: 280, startedAt: null } },
        w2: {}
      }
    }
    controller.timerBannerState = { participantKey: "w1", timerKey: "blood", expiresAt: 5_000 }

    controller.renderTimerBanner()

    expect(controller.timerBannerState).toBe(null)
    expect(controller.timerBannerTarget.style.display).toBe("none")
  })

  it("handles mat payload changes by switching match subscriptions and rendering", () => {
    const controller = buildController()
    controller.sourceModeValue = "mat_websocket"
    controller.currentQueueBoutNumber = 1001
    controller.currentBoutNumber = 1001
    controller.currentMatchId = 10
    controller.liveMatchData = { w1_stat: "Old" }
    controller.state = { metadata: { boutNumber: 1001 } }
    controller.setupMatchSubscription = vi.fn()
    controller.unsubscribeMatchSubscription = vi.fn()
    controller.loadSelectedBoutNumber = vi.fn()
    controller.loadStateFromLocalStorage = vi.fn()
    controller.resetTimerBannerState = vi.fn()
    controller.render = vi.fn()

    controller.handleMatPayload({
      queue1_bout_number: 1001,
      queue1_match_id: 10,
      selected_bout_number: 1002,
      selected_match_id: 11,
      last_match_result: "Result"
    })

    expect(controller.currentMatchId).toBe(11)
    expect(controller.currentBoutNumber).toBe(1002)
    expect(controller.lastMatchResult).toBe("Result")
    expect(controller.resetTimerBannerState).toHaveBeenCalledTimes(1)
    expect(controller.setupMatchSubscription).toHaveBeenCalledWith(11)
    expect(controller.render).toHaveBeenCalledTimes(1)
  })

  it("loads selected mat payload state from localStorage when the selected-bout key is missing", () => {
    const controller = buildController()
    const selectedState = {
      metadata: {
        boutNumber: 1002,
        ruleset: "folkstyle_usa",
        bracketPosition: "Bracket Round of 64"
      },
      matchResult: { finished: false }
    }

    window.localStorage.getItem = vi.fn((key) => {
      if (key === "match-state:8:1002") return JSON.stringify(selectedState)
      return null
    })
    controller.render = vi.fn()

    controller.handleMatPayload({
      queue1_bout_number: 1001,
      selected_bout_number: 1002,
      last_match_result: ""
    })

    expect(controller.currentBoutNumber).toBe(1002)
    expect(controller.state).toEqual(selectedState)
    expect(controller.render).toHaveBeenCalledTimes(1)
  })

  it("reloads selected bout and local state on selected-bout storage changes", () => {
    const controller = buildController()
    controller.currentQueueBoutNumber = 1001
    controller.currentBoutNumber = 1001
    controller.loadSelectedBoutNumber = vi.fn()
    controller.loadStateFromLocalStorage = vi.fn()
    controller.render = vi.fn()

    controller.handleStorageChange({ key: "mat-selected-bout:8:3" })

    expect(controller.loadSelectedBoutNumber).toHaveBeenCalledTimes(1)
    expect(controller.loadStateFromLocalStorage).toHaveBeenCalledTimes(1)
    expect(controller.render).toHaveBeenCalledTimes(1)
  })

  it("applies match websocket payloads into live match data and scoreboard state", () => {
    const controller = buildController()
    controller.currentBoutNumber = 1001
    controller.liveMatchData = { w1_stat: "Old" }
    controller.state = null

    controller.handleMatchPayload({
      scoreboard_state: {
        metadata: { boutNumber: 1002 },
        matchResult: { finished: true }
      },
      w1_stat: "T3",
      w2_stat: "E1",
      finished: 1
    })

    expect(controller.currentBoutNumber).toBe(1002)
    expect(controller.finished).toBe(true)
    expect(controller.liveMatchData).toEqual({
      w1_stat: "T3",
      w2_stat: "E1",
      finished: 1
    })
    expect(controller.state).toEqual({
      metadata: { boutNumber: 1002 },
      matchResult: { finished: true }
    })
  })
})
