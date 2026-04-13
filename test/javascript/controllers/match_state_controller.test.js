import { beforeEach, describe, expect, it, vi } from "vitest"
import { getMatchStateConfig } from "match-state-config"
import { buildInitialState } from "match-state-engine"
import MatchStateController from "../../../app/assets/javascripts/controllers/match_state_controller.js"

function buildController() {
  const controller = new MatchStateController()
  controller.element = {
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    querySelector: vi.fn(() => null)
  }
  controller.application = {
    getControllerForElementAndIdentifier: vi.fn()
  }
  controller.matchIdValue = 22
  controller.tournamentIdValue = 8
  controller.boutNumberValue = 1001
  controller.weightLabelValue = "106"
  controller.bracketPositionValue = "Bracket Round of 64"
  controller.rulesetValue = "folkstyle_usa"
  controller.w1IdValue = 11
  controller.w2IdValue = 12
  controller.w1NameValue = "Alpha"
  controller.w2NameValue = "Bravo"
  controller.w1SchoolValue = "School A"
  controller.w2SchoolValue = "School B"
  controller.hasW1StatFieldTarget = true
  controller.hasW2StatFieldTarget = true
  controller.w1StatFieldTarget = { value: "" }
  controller.w2StatFieldTarget = { value: "" }
  controller.hasMatchResultsPanelTarget = true
  controller.matchResultsPanelTarget = { querySelector: vi.fn(() => ({})) }
  return controller
}

describe("match state controller", () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    global.window = {
      localStorage: {
        getItem: vi.fn(() => null),
        setItem: vi.fn(),
        removeItem: vi.fn()
      },
      setInterval: vi.fn(() => 123),
      clearInterval: vi.fn(),
      setTimeout: vi.fn((fn) => {
        fn()
        return 1
      }),
      clearTimeout: vi.fn(),
      confirm: vi.fn(() => true)
    }
  })

  it("connect initializes state, restores persistence, renders, and subscribes", () => {
    const controller = buildController()
    controller.initializeState = vi.fn()
    controller.loadPersistedState = vi.fn()
    controller.syncClockFromActivePhase = vi.fn()
    controller.hasRunningClockOrTimer = vi.fn(() => true)
    controller.startTicking = vi.fn()
    controller.render = vi.fn()
    controller.setupSubscription = vi.fn()

    controller.connect()

    expect(controller.element.addEventListener).toHaveBeenCalledWith("click", controller.boundHandleClick)
    expect(controller.initializeState).toHaveBeenCalledTimes(1)
    expect(controller.loadPersistedState).toHaveBeenCalledTimes(1)
    expect(controller.syncClockFromActivePhase).toHaveBeenCalledTimes(1)
    expect(controller.startTicking).toHaveBeenCalledTimes(1)
    expect(controller.render).toHaveBeenCalledWith({ rebuildControls: true })
    expect(controller.setupSubscription).toHaveBeenCalledTimes(1)
  })

  it("applyAction recomputes and rerenders when a match action is accepted", () => {
    const controller = buildController()
    controller.config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    controller.state = buildInitialState(controller.config)
    controller.recomputeDerivedState = vi.fn()
    controller.render = vi.fn()

    controller.applyAction({
      dataset: {
        participantKey: "w1",
        actionKey: "takedown_3"
      }
    })

    expect(controller.recomputeDerivedState).toHaveBeenCalledTimes(1)
    expect(controller.render).toHaveBeenCalledWith({ rebuildControls: true })
  })

  it("applyChoice rerenders on defer and advances on a committed choice", () => {
    const controller = buildController()
    controller.config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    controller.state = buildInitialState(controller.config)
    controller.state.phaseIndex = 1
    controller.recomputeDerivedState = vi.fn()
    controller.render = vi.fn()
    controller.advancePhase = vi.fn()

    controller.applyChoice({
      dataset: {
        participantKey: "w1",
        choiceKey: "defer"
      }
    })

    expect(controller.recomputeDerivedState).toHaveBeenCalledTimes(1)
    expect(controller.render).toHaveBeenCalledWith({ rebuildControls: true })
    expect(controller.advancePhase).not.toHaveBeenCalled()

    controller.recomputeDerivedState.mockClear()
    controller.render.mockClear()

    controller.applyChoice({
      dataset: {
        participantKey: "w1",
        choiceKey: "top"
      }
    })

    expect(controller.advancePhase).toHaveBeenCalledTimes(1)
  })

  it("updateStatFieldsAndBroadcast writes hidden fields and pushes both channel payloads", () => {
    const controller = buildController()
    controller.derivedStats = vi.fn(() => ({ w1: "Period 1: T3", w2: "Period 1: E1" }))
    controller.pushDerivedStatsToChannel = vi.fn()
    controller.pushScoreboardStateToChannel = vi.fn()

    controller.updateStatFieldsAndBroadcast()

    expect(controller.w1StatFieldTarget.value).toBe("Period 1: T3")
    expect(controller.w2StatFieldTarget.value).toBe("Period 1: E1")
    expect(controller.lastDerivedStats).toEqual({ w1: "Period 1: T3", w2: "Period 1: E1" })
    expect(controller.pushDerivedStatsToChannel).toHaveBeenCalledTimes(1)
    expect(controller.pushScoreboardStateToChannel).toHaveBeenCalledTimes(1)
  })

  it("pushes derived stats and scoreboard payloads through the match subscription with dedupe", () => {
    const controller = buildController()
    controller.matchSubscription = { perform: vi.fn() }
    controller.lastDerivedStats = { w1: "Period 1: T3", w2: "Period 1: E1" }
    controller.scoreboardStatePayload = vi.fn(() => ({ participantScores: { w1: 3, w2: 1 } }))

    controller.pushDerivedStatsToChannel()
    controller.pushScoreboardStateToChannel()
    controller.pushDerivedStatsToChannel()
    controller.pushScoreboardStateToChannel()

    expect(controller.matchSubscription.perform).toHaveBeenCalledTimes(2)
    expect(controller.matchSubscription.perform).toHaveBeenNthCalledWith(1, "send_stat", {
      new_w1_stat: "Period 1: T3",
      new_w2_stat: "Period 1: E1"
    })
    expect(controller.matchSubscription.perform).toHaveBeenNthCalledWith(2, "send_scoreboard", {
      scoreboard_state: { participantScores: { w1: 3, w2: 1 } }
    })
  })

  it("starts, stops, and adjusts the active match clock", () => {
    const controller = buildController()
    controller.config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    controller.state = buildInitialState(controller.config)
    controller.render = vi.fn()
    controller.startTicking = vi.fn()
    controller.stopTicking = vi.fn()

    controller.startClock()
    expect(controller.activeClock().running).toBe(true)
    expect(controller.startTicking).toHaveBeenCalledTimes(1)
    expect(controller.render).toHaveBeenCalledTimes(1)

    controller.stopClock()
    expect(controller.activeClock().running).toBe(false)
    expect(controller.stopTicking).toHaveBeenCalledTimes(1)

    const beforeAdjustment = controller.activeClock().remainingSeconds
    controller.adjustClock(-1)
    expect(controller.activeClock().remainingSeconds).toBe(beforeAdjustment - 1)
  })

  it("stopping an auxiliary timer records a timer-used event", () => {
    const controller = buildController()
    controller.config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    controller.state = buildInitialState(controller.config)
    controller.state.timers.w1.blood.running = true
    controller.state.timers.w1.blood.startedAt = 1_000
    controller.state.timers.w1.blood.remainingSeconds = 300
    controller.render = vi.fn()
    vi.spyOn(Date, "now").mockReturnValue(6_000)

    controller.stopAuxiliaryTimer("w1", "blood")

    expect(controller.state.timers.w1.blood.running).toBe(false)
    expect(controller.state.events).toHaveLength(1)
    expect(controller.state.events[0]).toMatchObject({
      participantKey: "w1",
      actionKey: "timer_used_blood",
      elapsedSeconds: 5
    })
    expect(controller.render).toHaveBeenCalledTimes(1)
  })

  it("deletes, swaps events, and swaps whole phases through button dataset ids", () => {
    const controller = buildController()
    controller.config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    controller.state = buildInitialState(controller.config)
    controller.state.events = [
      {
        id: 1,
        phaseKey: "period_1",
        phaseLabel: "Period 1",
        clockSeconds: 120,
        participantKey: "w1",
        actionKey: "takedown_3"
      },
      {
        id: 2,
        phaseKey: "period_1",
        phaseLabel: "Period 1",
        clockSeconds: 100,
        participantKey: "w2",
        actionKey: "escape_1"
      }
    ]
    controller.recomputeDerivedState = vi.fn()
    controller.render = vi.fn()

    controller.swapEvent({ dataset: { eventId: "1" } })
    expect(controller.state.events[0].participantKey).toBe("w2")

    controller.swapPhase({ dataset: { phaseKey: "period_1" } })
    expect(controller.state.events.map((eventRecord) => eventRecord.participantKey)).toEqual(["w1", "w1"])

    controller.deleteEvent({ dataset: { eventId: "2" } })
    expect(controller.state.events.map((eventRecord) => eventRecord.id)).toEqual([1])
    expect(controller.recomputeDerivedState).toHaveBeenCalledTimes(3)
    expect(controller.render).toHaveBeenCalledTimes(3)
  })

  it("delegated click dispatches dynamic state buttons", () => {
    const controller = buildController()
    controller.applyAction = vi.fn()
    const button = {
      dataset: { matchStateButton: "score-action" }
    }

    controller.handleDelegatedClick({
      target: {
        closest: vi.fn(() => button)
      }
    })

    expect(controller.applyAction).toHaveBeenCalledWith(button)
  })

  it("applyMatchResultDefaults forwards derived defaults to the nested match-score controller", () => {
    const controller = buildController()
    controller.config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    controller.state = buildInitialState(controller.config)
    controller.state.participantScores = { w1: 4, w2: 2 }
    controller.currentPhase = vi.fn(() => controller.config.phaseSequence[0])
    controller.accumulatedMatchSeconds = vi.fn(() => 69)
    const nested = { applyDefaultResults: vi.fn() }
    controller.application.getControllerForElementAndIdentifier.mockReturnValue(nested)

    controller.applyMatchResultDefaults()

    expect(nested.applyDefaultResults).toHaveBeenCalledTimes(1)
    expect(nested.applyDefaultResults.mock.calls[0][0]).toMatchObject({
      winnerId: 11,
      winnerScore: 4,
      loserScore: 2
    })
  })

  it("resetMatch reinitializes state and clears persistence when confirmed", () => {
    const controller = buildController()
    controller.initializeState = vi.fn()
    controller.syncClockFromActivePhase = vi.fn()
    controller.clearPersistedState = vi.fn()
    controller.render = vi.fn()
    controller.stopTicking = vi.fn()

    controller.resetMatch()

    expect(window.confirm).toHaveBeenCalledTimes(1)
    expect(controller.stopTicking).toHaveBeenCalledTimes(1)
    expect(controller.initializeState).toHaveBeenCalledTimes(1)
    expect(controller.syncClockFromActivePhase).toHaveBeenCalledTimes(1)
    expect(controller.clearPersistedState).toHaveBeenCalledTimes(1)
    expect(controller.render).toHaveBeenCalledWith({ rebuildControls: true })
  })

  it("loadPersistedState restores saved state and clears invalid saved state", () => {
    const controller = buildController()
    controller.config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    controller.buildInitialState = vi.fn(() => ({ fresh: true }))
    controller.clearPersistedState = vi.fn()

    window.localStorage.getItem.mockReturnValueOnce('{"participantScores":{"w1":3,"w2":1}}')
    controller.loadPersistedState()
    expect(controller.state.participantScores).toEqual({ w1: 3, w2: 1 })

    window.localStorage.getItem.mockReturnValue("{bad-json")
    controller.loadPersistedState()
    expect(controller.clearPersistedState).toHaveBeenCalledTimes(1)
    expect(controller.state).toEqual({ fresh: true })
  })
})
