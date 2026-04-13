import { describe, expect, it } from "vitest"
import {
  buildScoreboardContext,
  connectionPlan,
  applyMatchPayloadContext,
  applyMatPayloadContext,
  applyStatePayloadContext,
  extractLiveMatchData,
  matchStorageKey,
  selectedBoutNumber,
  storageChangePlan,
  selectedBoutStorageKey
} from "match-state-scoreboard-state"

describe("match state scoreboard state helpers", () => {
  it("builds the default scoreboard controller context", () => {
    expect(buildScoreboardContext({ initialBoutNumber: 1001, matchId: 55 })).toEqual({
      currentQueueBoutNumber: 1001,
      currentBoutNumber: 1001,
      currentMatchId: 55,
      liveMatchData: {},
      lastMatchResult: "",
      state: null,
      finished: false,
      timerBannerState: null,
      previousTimerSnapshot: {}
    })
  })

  it("builds tournament-scoped storage keys", () => {
    expect(selectedBoutStorageKey(4, 2)).toBe("mat-selected-bout:4:2")
    expect(matchStorageKey(4, 1007)).toBe("match-state:4:1007")
    expect(matchStorageKey(4, null)).toBe(null)
  })

  it("builds connection plans by source mode", () => {
    expect(connectionPlan("localstorage", 11)).toEqual({
      useStorageListener: true,
      subscribeMat: true,
      subscribeMatch: false,
      matchId: null,
      loadSelectedBout: true,
      loadLocalState: true
    })

    expect(connectionPlan("mat_websocket", 11)).toEqual({
      useStorageListener: false,
      subscribeMat: true,
      subscribeMatch: true,
      matchId: 11,
      loadSelectedBout: false,
      loadLocalState: false
    })

    expect(connectionPlan("websocket", 11)).toEqual({
      useStorageListener: false,
      subscribeMat: false,
      subscribeMatch: true,
      matchId: 11,
      loadSelectedBout: false,
      loadLocalState: false
    })
  })

  it("extracts live match fields from a websocket payload", () => {
    expect(extractLiveMatchData({
      w1_stat: "T3",
      w2_stat: "E1",
      score: "3-1",
      win_type: "Decision",
      winner_name: "Alpha",
      finished: 1,
      ignored: "value"
    })).toEqual({
      w1_stat: "T3",
      w2_stat: "E1",
      score: "3-1",
      win_type: "Decision",
      winner_name: "Alpha",
      finished: 1
    })
  })

  it("applies scoreboard state payload context", () => {
    const context = applyStatePayloadContext(
      { currentBoutNumber: 1001, finished: false, state: null },
      {
        metadata: { boutNumber: 1002 },
        matchResult: { finished: true }
      }
    )

    expect(context.currentBoutNumber).toBe(1002)
    expect(context.finished).toBe(true)
    expect(context.state).toEqual({
      metadata: { boutNumber: 1002 },
      matchResult: { finished: true }
    })
  })

  it("merges websocket match payload into current scoreboard context", () => {
    const currentContext = {
      currentBoutNumber: 1001,
      finished: false,
      liveMatchData: { w1_stat: "Old" },
      state: { metadata: { boutNumber: 1001 } }
    }

    const nextContext = applyMatchPayloadContext(currentContext, {
      scoreboard_state: {
        metadata: { boutNumber: 1003 },
        matchResult: { finished: true }
      },
      w1_stat: "T3",
      w2_stat: "E1",
      score: "3-1",
      finished: 1
    })

    expect(nextContext.currentBoutNumber).toBe(1003)
    expect(nextContext.finished).toBe(true)
    expect(nextContext.liveMatchData).toEqual({
      w1_stat: "T3",
      w2_stat: "E1",
      score: "3-1",
      finished: 1
    })
    expect(nextContext.state).toEqual({
      metadata: { boutNumber: 1003 },
      matchResult: { finished: true }
    })
  })

  it("updates localstorage scoreboard context from mat payload", () => {
    const nextContext = applyMatPayloadContext(
      {
        sourceMode: "localstorage",
        currentQueueBoutNumber: null,
        lastMatchResult: "",
        currentMatchId: null,
        currentBoutNumber: null,
        state: null,
        liveMatchData: {}
      },
      {
        queue1_bout_number: 1001,
        last_match_result: "Result text"
      }
    )

    expect(nextContext).toMatchObject({
      currentQueueBoutNumber: 1001,
      lastMatchResult: "Result text",
      loadSelectedBout: true,
      loadLocalState: true,
      renderNow: true
    })
  })

  it("uses the selected mat bout as the localstorage scoreboard fallback", () => {
    const nextContext = applyMatPayloadContext(
      {
        sourceMode: "localstorage",
        currentQueueBoutNumber: null,
        lastMatchResult: "",
        currentMatchId: null,
        currentBoutNumber: null,
        state: null,
        liveMatchData: {}
      },
      {
        queue1_bout_number: 1001,
        selected_bout_number: 1003,
        last_match_result: ""
      }
    )

    expect(nextContext.currentQueueBoutNumber).toBe(1003)
    expect(nextContext.loadSelectedBout).toBe(true)
    expect(nextContext.loadLocalState).toBe(true)
  })

  it("derives storage change instructions for selected bout and match state keys", () => {
    const context = { currentBoutNumber: 1001 }

    expect(storageChangePlan(context, "mat-selected-bout:4:2", 4, 2)).toEqual({
      loadSelectedBout: true,
      loadLocalState: true,
      renderNow: true
    })

    expect(storageChangePlan(context, "match-state:4:1001", 4, 2)).toEqual({
      loadSelectedBout: false,
      loadLocalState: true,
      renderNow: true
    })

    expect(storageChangePlan(context, "other-key", 4, 2)).toEqual({
      loadSelectedBout: false,
      loadLocalState: false,
      renderNow: false
    })
  })

  it("prefers selected bout numbers and falls back to queue bout", () => {
    expect(selectedBoutNumber({ boutNumber: 1004 }, 1001)).toBe(1004)
    expect(selectedBoutNumber(null, 1001)).toBe(1001)
  })

  it("clears websocket scoreboard context when the mat has no active match", () => {
    const nextContext = applyMatPayloadContext(
      {
        sourceMode: "mat_websocket",
        currentQueueBoutNumber: 1001,
        currentMatchId: 10,
        currentBoutNumber: 1001,
        liveMatchData: { w1_stat: "T3" },
        state: { metadata: { boutNumber: 1001 } },
        lastMatchResult: ""
      },
      {
        queue1_bout_number: null,
        queue1_match_id: null,
        selected_bout_number: null,
        selected_match_id: null,
        last_match_result: "Last result"
      }
    )

    expect(nextContext).toMatchObject({
      currentQueueBoutNumber: null,
      currentMatchId: null,
      currentBoutNumber: null,
      state: null,
      liveMatchData: {},
      lastMatchResult: "Last result",
      resetTimerBanner: true,
      unsubscribeMatch: true,
      subscribeMatchId: null,
      renderNow: true
    })
  })

  it("switches websocket scoreboard subscriptions when the selected match changes", () => {
    const nextContext = applyMatPayloadContext(
      {
        sourceMode: "mat_websocket",
        currentQueueBoutNumber: 1001,
        currentMatchId: 10,
        currentBoutNumber: 1001,
        liveMatchData: { w1_stat: "T3" },
        state: { metadata: { boutNumber: 1001 } },
        lastMatchResult: ""
      },
      {
        queue1_bout_number: 1001,
        queue1_match_id: 10,
        selected_bout_number: 1002,
        selected_match_id: 11,
        last_match_result: ""
      }
    )

    expect(nextContext).toMatchObject({
      currentQueueBoutNumber: 1001,
      currentMatchId: 11,
      currentBoutNumber: 1002,
      state: null,
      liveMatchData: {},
      resetTimerBanner: true,
      subscribeMatchId: 11,
      renderNow: true
    })
  })

  it("keeps current websocket subscription when the selected match is unchanged", () => {
    const state = { metadata: { boutNumber: 1002 } }
    const liveMatchData = { w1_stat: "T3" }

    const nextContext = applyMatPayloadContext(
      {
        sourceMode: "mat_websocket",
        currentQueueBoutNumber: 1001,
        currentMatchId: 11,
        currentBoutNumber: 1002,
        liveMatchData,
        state,
        lastMatchResult: ""
      },
      {
        queue1_bout_number: 1001,
        queue1_match_id: 10,
        selected_bout_number: 1002,
        selected_match_id: 11,
        last_match_result: "Result"
      }
    )

    expect(nextContext.currentMatchId).toBe(11)
    expect(nextContext.currentBoutNumber).toBe(1002)
    expect(nextContext.state).toBe(state)
    expect(nextContext.liveMatchData).toBe(liveMatchData)
    expect(nextContext.subscribeMatchId).toBe(null)
    expect(nextContext.renderNow).toBe(false)
    expect(nextContext.lastMatchResult).toBe("Result")
  })
})
