import { describe, expect, it } from "vitest"
import { getMatchStateConfig } from "match-state-config"
import { buildInitialState } from "match-state-engine"
import {
  boardColors,
  buildRunningTimerSnapshot,
  emptyBoardViewModel,
  currentClockText,
  detectRecentlyStoppedTimer,
  mainClockRunning,
  nextTimerBannerState,
  participantDisplayLabel,
  participantForColor,
  populatedBoardViewModel,
  timerBannerRenderState,
  timerBannerViewModel,
  timerIndicatorLabel
} from "match-state-scoreboard-presenters"

describe("match state scoreboard presenters", () => {
  it("maps colors to participants and labels", () => {
    const state = {
      assignment: { w1: "red", w2: "green" },
      metadata: { w1Name: "Alpha", w2Name: "Bravo" }
    }

    expect(participantForColor(state, "red")).toBe("w1")
    expect(participantForColor(state, "green")).toBe("w2")
    expect(participantDisplayLabel(state, "w1")).toBe("Red Alpha")
    expect(participantDisplayLabel(state, "w2")).toBe("Green Bravo")
  })

  it("formats the current clock from running phase state", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const state = buildInitialState(config)
    state.phaseIndex = 0
    state.clocksByPhase.period_1.running = true
    state.clocksByPhase.period_1.startedAt = 1_000
    state.clocksByPhase.period_1.remainingSeconds = 120

    expect(currentClockText(config, state, (seconds) => `F-${seconds}`, 11_000)).toBe("F-110")
    expect(mainClockRunning(config, state)).toBe(true)
  })

  it("builds timer indicator and banner view models from running timers", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const state = buildInitialState(config)
    state.metadata = { w1Name: "Alpha", w2Name: "Bravo" }
    state.timers.w1.blood.running = true
    state.timers.w1.blood.startedAt = 1_000
    state.timers.w1.blood.remainingSeconds = 300

    expect(timerIndicatorLabel(config, state, "w1", (seconds) => `F-${seconds}`, 21_000)).toBe("Blood: F-20")

    const banner = timerBannerViewModel(config, state, { participantKey: "w1", timerKey: "blood", expiresAt: null }, (seconds) => `F-${seconds}`, 21_000)
    expect(banner).toEqual({
      color: "green",
      label: "Green Alpha Blood Running",
      clockText: "F-20"
    })
  })

  it("detects recently stopped timers from the snapshot", () => {
    const state = {
      timers: {
        w1: { blood: { running: false } },
        w2: { injury: { running: true } }
      }
    }
    const snapshot = {
      "w1:blood": true,
      "w2:injury": true
    }

    expect(detectRecentlyStoppedTimer(state, snapshot)).toEqual({ participantKey: "w1", timerKey: "blood" })
    expect(buildRunningTimerSnapshot(state)).toEqual({
      "w1:blood": false,
      "w2:injury": true
    })
  })

  it("builds populated and empty board view models", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const state = buildInitialState(config)
    state.metadata = {
      w1Name: "Alpha",
      w2Name: "Bravo",
      w1School: "School A",
      w2School: "School B",
      weightLabel: "106"
    }
    state.participantScores = { w1: 4, w2: 1 }
    state.assignment = { w1: "green", w2: "red" }

    const populated = populatedBoardViewModel(
      config,
      state,
      { w1_stat: "T3", w2_stat: "E1" },
      1001,
      (seconds) => `F-${seconds}`
    )

    expect(populated).toMatchObject({
      isEmpty: false,
      redName: "Bravo",
      redSchool: "School B",
      redScore: "1",
      greenName: "Alpha",
      greenSchool: "School A",
      greenScore: "4",
      weightLabel: "Weight 106",
      boutLabel: "Bout 1001",
      redStats: "E1",
      greenStats: "T3"
    })

    expect(emptyBoardViewModel(1002, "Last result")).toEqual({
      isEmpty: true,
      redName: "NO MATCH",
      redSchool: "",
      redScore: "0",
      redTimerIndicator: "",
      greenName: "NO MATCH",
      greenSchool: "",
      greenScore: "0",
      greenTimerIndicator: "",
      clockText: "-",
      phaseLabel: "No Match",
      weightLabel: "Weight -",
      boutLabel: "Bout 1002",
      redStats: "",
      greenStats: "",
      lastMatchResult: "Last result"
    })
  })

  it("builds next timer banner state for running and recently stopped timers", () => {
    const runningState = {
      timers: {
        w1: { blood: { running: true } },
        w2: {}
      }
    }

    expect(nextTimerBannerState(runningState, {})).toEqual({
      timerBannerState: {
        participantKey: "w1",
        timerKey: "blood",
        expiresAt: null
      },
      previousTimerSnapshot: {
        "w1:blood": true
      }
    })

    const stoppedState = {
      timers: {
        w1: { blood: { running: false } },
        w2: {}
      }
    }

    const stoppedResult = nextTimerBannerState(stoppedState, { "w1:blood": true }, 5_000)
    expect(stoppedResult).toEqual({
      timerBannerState: {
        participantKey: "w1",
        timerKey: "blood",
        expiresAt: 15_000
      },
      previousTimerSnapshot: {
        "w1:blood": false
      }
    })
  })

  it("builds board colors and timer banner render decisions", () => {
    expect(boardColors(true)).toEqual({
      red: "#000",
      center: "#000",
      green: "#000"
    })
    expect(boardColors(false)).toEqual({
      red: "#c91f1f",
      center: "#050505",
      green: "#1cab2d"
    })

    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const state = buildInitialState(config)
    state.metadata = { w1Name: "Alpha", w2Name: "Bravo" }
    state.timers.w1.blood.running = true
    state.timers.w1.blood.startedAt = 1_000
    state.timers.w1.blood.remainingSeconds = 300

    expect(timerBannerRenderState(
      config,
      state,
      { participantKey: "w1", timerKey: "blood", expiresAt: null },
      (seconds) => `F-${seconds}`,
      11_000
    )).toEqual({
      timerBannerState: { participantKey: "w1", timerKey: "blood", expiresAt: null },
      visible: true,
      viewModel: {
        color: "green",
        label: "Green Alpha Blood Running",
        clockText: "F-10"
      }
    })

    state.clocksByPhase.period_1.running = true
    state.clocksByPhase.period_1.startedAt = 1_000
    state.clocksByPhase.period_1.remainingSeconds = 120

    expect(timerBannerRenderState(
      config,
      state,
      { participantKey: "w1", timerKey: "blood", expiresAt: 20_000 },
      (seconds) => `F-${seconds}`,
      11_000
    )).toEqual({
      timerBannerState: null,
      visible: false,
      viewModel: null
    })
  })
})
