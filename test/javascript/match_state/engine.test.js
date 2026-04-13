import { describe, expect, it } from "vitest"
import { getMatchStateConfig } from "match-state-config"
import {
  accumulatedMatchSeconds,
  activeClockForPhase,
  adjustClockState,
  applyChoiceAction,
  applyMatchAction,
  buildInitialState,
  deleteEventFromState,
  derivedStats,
  hasRunningClockOrTimer,
  matchResultDefaults,
  moveToNextPhase,
  moveToPreviousPhase,
  recordProgressiveAction,
  recomputeDerivedState,
  scoreboardStatePayload,
  startAuxiliaryTimerState,
  startClockState,
  stopAuxiliaryTimerState,
  stopClockState,
  stopAllAuxiliaryTimers,
  swapEventParticipants,
  syncClockSnapshot,
  swapPhaseParticipants
} from "match-state-engine"

function buildEvent(overrides = {}) {
  return {
    id: 1,
    phaseKey: "period_1",
    phaseLabel: "Period 1",
    clockSeconds: 120,
    participantKey: "w1",
    actionKey: "takedown_3",
    ...overrides
  }
}

describe("match state engine", () => {
  it("replays takedown and escape into score and control", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const state = buildInitialState(config)

    state.events = [
      buildEvent(),
      buildEvent({
        id: 2,
        participantKey: "w2",
        actionKey: "escape_1",
        clockSeconds: 80
      })
    ]

    recomputeDerivedState(config, state)

    expect(state.participantScores).toEqual({ w1: 3, w2: 1 })
    expect(state.control).toBe("neutral")
    expect(state.displayControl).toBe("neutral")
  })

  it("stores non defer choices and applies chosen starting control to later periods", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const state = buildInitialState(config)

    state.phaseIndex = 2
    state.events = [
      buildEvent({
        id: 1,
        phaseKey: "choice_1",
        phaseLabel: "Choice 1",
        clockSeconds: 0,
        participantKey: "w1",
        actionKey: "choice_top"
      })
    ]

    recomputeDerivedState(config, state)

    expect(state.selections.choice_1).toEqual({ participantKey: "w1", choiceKey: "top" })
    expect(state.control).toBe("w1_control")
    expect(state.displayControl).toBe("w1_control")
  })

  it("ignores defer as a final selection", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const state = buildInitialState(config)

    state.phaseIndex = 2
    state.events = [
      buildEvent({
        id: 1,
        phaseKey: "choice_1",
        phaseLabel: "Choice 1",
        clockSeconds: 0,
        participantKey: "w1",
        actionKey: "choice_defer"
      })
    ]

    recomputeDerivedState(config, state)

    expect(state.selections).toEqual({})
    expect(state.control).toBe("neutral")
    expect(state.displayControl).toBe("neutral")
  })

  it("derives legacy stats grouped by period", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const stats = derivedStats(config, [
      buildEvent(),
      buildEvent({
        id: 2,
        participantKey: "w2",
        actionKey: "escape_1",
        clockSeconds: 80
      }),
      buildEvent({
        id: 3,
        phaseKey: "choice_1",
        phaseLabel: "Choice 1",
        clockSeconds: 0,
        participantKey: "w1",
        actionKey: "choice_defer"
      })
    ])

    expect(stats.w1).toBe("Period 1: T3\nChoice 1: |Deferred|")
    expect(stats.w2).toBe("Period 1: E1")
  })

  it("derives accumulated match time from period clocks", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const state = buildInitialState(config)

    state.phaseIndex = 2
    state.clocksByPhase.period_1.remainingSeconds = 42
    state.clocksByPhase.period_2.remainingSeconds = 75
    state.clocksByPhase.period_3.remainingSeconds = 120

    const total = accumulatedMatchSeconds(config, state, "period_2")

    expect(total).toBe((120 - 42) + (120 - 75))
  })

  it("builds scoreboard payload from canonical state and metadata", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const state = buildInitialState(config)
    state.participantScores = { w1: 6, w2: 2 }
    state.phaseIndex = 2

    const payload = scoreboardStatePayload(config, state, {
      tournamentId: 1,
      boutNumber: 1001,
      weightLabel: "106",
      ruleset: "folkstyle_usa",
      bracketPosition: "Bracket Round of 64",
      w1Name: "Wrestler 1",
      w2Name: "Wrestler 2",
      w1School: "School A",
      w2School: "School B"
    })

    expect(payload.participantScores).toEqual({ w1: 6, w2: 2 })
    expect(payload.phaseIndex).toBe(2)
    expect(payload.metadata.boutNumber).toBe(1001)
    expect(payload.metadata.w1Name).toBe("Wrestler 1")
    expect(payload.matchResult).toEqual({ finished: false })
  })

  it("records progressive penalty with linked awarded points", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const state = buildInitialState(config)
    state.nextEventId = 1
    state.nextEventGroupId = 1

    const buildControllerStyleEvent = (participantKey, actionKey, options = {}) => ({
      id: state.nextEventId++,
      phaseKey: "period_1",
      phaseLabel: "Period 1",
      clockSeconds: 120,
      participantKey,
      actionKey,
      actionGroupId: options.actionGroupId
    })

    recordProgressiveAction(config, state, "w1", "penalty", buildControllerStyleEvent)
    recordProgressiveAction(config, state, "w1", "penalty", buildControllerStyleEvent)
    recordProgressiveAction(config, state, "w1", "penalty", buildControllerStyleEvent)

    expect(state.events.map((eventRecord) => [eventRecord.participantKey, eventRecord.actionKey])).toEqual([
      ["w1", "penalty"],
      ["w2", "plus_1"],
      ["w1", "penalty"],
      ["w2", "plus_1"],
      ["w1", "penalty"],
      ["w2", "plus_2"]
    ])
  })

  it("applies a normal match action by creating one event", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const state = buildInitialState(config)

    const applied = applyMatchAction(config, state, config.phaseSequence[0], 118, "w1", "takedown_3")

    expect(applied).toBe(true)
    expect(state.events).toHaveLength(1)
    expect(state.events[0]).toMatchObject({
      phaseKey: "period_1",
      clockSeconds: 118,
      participantKey: "w1",
      actionKey: "takedown_3"
    })
  })

  it("applies a progressive action by creating offense and linked award events when earned", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const state = buildInitialState(config)

    expect(applyMatchAction(config, state, config.phaseSequence[0], 118, "w1", "stalling")).toBe(true)
    expect(applyMatchAction(config, state, config.phaseSequence[0], 110, "w1", "stalling")).toBe(true)

    expect(state.events.map((eventRecord) => [eventRecord.participantKey, eventRecord.actionKey])).toEqual([
      ["w1", "stalling"],
      ["w1", "stalling"],
      ["w2", "plus_1"]
    ])
  })

  it("applies a defer choice without storing a final selection", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const state = buildInitialState(config)
    const choicePhase = config.phaseSequence[1]

    const result = applyChoiceAction(state, choicePhase, 0, "w1", "defer")

    expect(result).toEqual({ applied: true, deferred: true })
    expect(state.events).toHaveLength(1)
    expect(state.events[0].actionKey).toBe("choice_defer")
    expect(state.selections).toEqual({})
  })

  it("applies a non defer choice and stores the selection", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const state = buildInitialState(config)
    const choicePhase = config.phaseSequence[1]

    const result = applyChoiceAction(state, choicePhase, 0, "w2", "bottom")

    expect(result).toEqual({ applied: true, deferred: false })
    expect(state.events[0].actionKey).toBe("choice_bottom")
    expect(state.selections.choice_1).toEqual({ participantKey: "w2", choiceKey: "bottom" })
  })

  it("deleting a timer-used event restores timer time", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const state = buildInitialState(config)
    state.timers.w1.injury.remainingSeconds = 60
    state.events = [
      buildEvent({
        id: 1,
        participantKey: "w1",
        actionKey: "timer_used_injury",
        elapsedSeconds: 20
      })
    ]

    const deleted = deleteEventFromState(config, state, 1)

    expect(deleted).toBe(true)
    expect(state.events).toEqual([])
    expect(state.timers.w1.injury.remainingSeconds).toBe(80)
  })

  it("deleting a scoring event replays control from the remaining history", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const state = buildInitialState(config)
    state.events = [
      buildEvent({
        id: 1,
        participantKey: "w1",
        actionKey: "takedown_3",
        clockSeconds: 118
      }),
      buildEvent({
        id: 2,
        participantKey: "w2",
        actionKey: "escape_1",
        clockSeconds: 90
      })
    ]

    recomputeDerivedState(config, state)
    expect(state.control).toBe("neutral")

    expect(deleteEventFromState(config, state, 2)).toBe(true)
    recomputeDerivedState(config, state)

    expect(state.participantScores).toEqual({ w1: 3, w2: 0 })
    expect(state.control).toBe("w1_control")
    expect(state.displayControl).toBe("w1_control")
  })

  it("deleting an earlier-period event preserves display control for the selected later period", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const state = buildInitialState(config)
    state.phaseIndex = 2
    state.events = [
      buildEvent({
        id: 1,
        phaseKey: "period_1",
        phaseLabel: "Period 1",
        participantKey: "w1",
        actionKey: "takedown_3",
        clockSeconds: 118
      }),
      buildEvent({
        id: 2,
        phaseKey: "period_1",
        phaseLabel: "Period 1",
        participantKey: "w2",
        actionKey: "escape_1",
        clockSeconds: 90
      }),
      buildEvent({
        id: 3,
        phaseKey: "choice_1",
        phaseLabel: "Choice 1",
        participantKey: "w2",
        actionKey: "choice_bottom",
        clockSeconds: 0
      }),
      buildEvent({
        id: 4,
        phaseKey: "period_2",
        phaseLabel: "Period 2",
        participantKey: "w2",
        actionKey: "nearfall_2",
        clockSeconds: 110
      })
    ]

    recomputeDerivedState(config, state)
    expect(state.displayControl).toBe("w1_control")

    expect(deleteEventFromState(config, state, 2)).toBe(true)
    recomputeDerivedState(config, state)

    expect(state.participantScores).toEqual({ w1: 3, w2: 2 })
    expect(state.displayControl).toBe("w1_control")
  })

  it("swapping a timer-used event moves the used time to the other wrestler", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const state = buildInitialState(config)
    state.timers.w1.blood.remainingSeconds = 240
    state.timers.w2.blood.remainingSeconds = 260
    state.events = [
      buildEvent({
        id: 1,
        participantKey: "w1",
        actionKey: "timer_used_blood",
        elapsedSeconds: 30
      })
    ]

    const swapped = swapEventParticipants(config, state, 1)

    expect(swapped).toBe(true)
    expect(state.events[0].participantKey).toBe("w2")
    expect(state.timers.w1.blood.remainingSeconds).toBe(270)
    expect(state.timers.w2.blood.remainingSeconds).toBe(230)
  })

  it("swapping a whole period flips all participants in that period", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const state = buildInitialState(config)
    state.events = [
      buildEvent({
        id: 1,
        participantKey: "w1",
        actionKey: "takedown_3"
      }),
      buildEvent({
        id: 2,
        participantKey: "w2",
        actionKey: "escape_1",
        clockSeconds: 80
      }),
      buildEvent({
        id: 3,
        phaseKey: "choice_1",
        phaseLabel: "Choice 1",
        participantKey: "w1",
        actionKey: "choice_defer",
        clockSeconds: 0
      })
    ]

    const swapped = swapPhaseParticipants(config, state, "period_1")

    expect(swapped).toBe(true)
    expect(state.events.slice(0, 2).map((eventRecord) => eventRecord.participantKey)).toEqual(["w2", "w1"])
    expect(state.events[2].participantKey).toBe("w1")
  })

  it("starts, stops, and adjusts a running match clock", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const state = buildInitialState(config)
    const activeClock = state.clocksByPhase.period_1

    expect(startClockState(activeClock, 1_000)).toBe(true)
    expect(activeClock.running).toBe(true)
    expect(activeClock.startedAt).toBe(1_000)

    expect(adjustClockState(activeClock, -10, 6_000)).toBe(true)
    expect(activeClock.remainingSeconds).toBe(105)
    expect(activeClock.startedAt).toBe(6_000)

    expect(stopClockState(activeClock, 11_000)).toBe(true)
    expect(activeClock.running).toBe(false)
    expect(activeClock.remainingSeconds).toBe(100)
    expect(syncClockSnapshot(activeClock)).toEqual({
      durationSeconds: 120,
      remainingSeconds: 100,
      running: false,
      startedAt: null
    })
  })

  it("starts and stops an auxiliary timer with elapsed time", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const timerState = buildInitialState(config).timers.w1.injury

    expect(startAuxiliaryTimerState(timerState, 2_000)).toBe(true)
    const result = stopAuxiliaryTimerState(timerState, 17_000)

    expect(result).toEqual({ stopped: true, elapsedSeconds: 15 })
    expect(timerState.running).toBe(false)
    expect(timerState.remainingSeconds).toBe(75)
  })

  it("derives match result defaults from score and overtime context", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const state = buildInitialState(config)
    state.participantScores = { w1: 4, w2: 2 }

    const defaults = matchResultDefaults(state, {
      w1Id: 11,
      w2Id: 22,
      currentPhase: config.phaseSequence.find((phase) => phase.key === "sv_1"),
      accumulationSeconds: 83
    })

    expect(defaults).toEqual({
      winnerId: 11,
      overtimeType: "SV-1",
      winnerScore: 4,
      loserScore: 2,
      pinMinutes: 1,
      pinSeconds: 23
    })
  })

  it("moves between phases and resets control to the new phase base", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const state = buildInitialState(config)
    state.control = "w1_control"

    expect(moveToNextPhase(config, state)).toBe(true)
    expect(state.phaseIndex).toBe(1)

    state.selections.choice_1 = { participantKey: "w2", choiceKey: "bottom" }
    expect(moveToNextPhase(config, state)).toBe(true)
    expect(state.phaseIndex).toBe(2)
    expect(state.control).toBe("w1_control")

    expect(moveToPreviousPhase(config, state)).toBe(true)
    expect(state.phaseIndex).toBe(1)
  })

  it("finds the active clock for a timed phase and reports running state", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const state = buildInitialState(config)
    const periodOne = config.phaseSequence[0]
    const choiceOne = config.phaseSequence[1]

    expect(activeClockForPhase(state, periodOne)).toBe(state.clocksByPhase.period_1)
    expect(activeClockForPhase(state, choiceOne)).toBe(null)
    expect(hasRunningClockOrTimer(state)).toBe(false)

    state.clocksByPhase.period_1.running = true
    expect(hasRunningClockOrTimer(state)).toBe(true)
  })

  it("stops all running auxiliary timers in place", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const state = buildInitialState(config)
    state.timers.w1.blood.running = true
    state.timers.w1.blood.startedAt = 1_000
    state.timers.w1.blood.remainingSeconds = 300
    state.timers.w2.injury.running = true
    state.timers.w2.injury.startedAt = 5_000
    state.timers.w2.injury.remainingSeconds = 90

    stopAllAuxiliaryTimers(state, 11_000)

    expect(state.timers.w1.blood).toMatchObject({ running: false, startedAt: null, remainingSeconds: 290 })
    expect(state.timers.w2.injury).toMatchObject({ running: false, startedAt: null, remainingSeconds: 84 })
  })
})
