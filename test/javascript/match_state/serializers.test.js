import { describe, expect, it } from "vitest"
import { getMatchStateConfig } from "match-state-config"
import { buildInitialState } from "match-state-engine"
import {
  buildMatchMetadata,
  buildPersistedState,
  buildStorageKey,
  restorePersistedState
} from "match-state-serializers"

describe("match state serializers", () => {
  it("builds a tournament and bout scoped storage key", () => {
    expect(buildStorageKey(12, 1007)).toBe("match-state:12:1007")
  })

  it("builds match metadata for persistence and scoreboard payloads", () => {
    expect(buildMatchMetadata({
      tournamentId: 1,
      boutNumber: 1001,
      weightLabel: "106",
      ruleset: "folkstyle_usa",
      bracketPosition: "Bracket Round of 64",
      w1Name: "W1",
      w2Name: "W2",
      w1School: "School 1",
      w2School: "School 2"
    })).toEqual({
      tournamentId: 1,
      boutNumber: 1001,
      weightLabel: "106",
      ruleset: "folkstyle_usa",
      bracketPosition: "Bracket Round of 64",
      w1Name: "W1",
      w2Name: "W2",
      w1School: "School 1",
      w2School: "School 2"
    })
  })

  it("builds persisted state with metadata", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const state = buildInitialState(config)
    state.participantScores = { w1: 7, w2: 3 }

    const persisted = buildPersistedState(state, { tournamentId: 1, boutNumber: 1001 })

    expect(persisted.participantScores).toEqual({ w1: 7, w2: 3 })
    expect(persisted.metadata).toEqual({ tournamentId: 1, boutNumber: 1001 })
  })

  it("restores persisted state over initial defaults", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const restored = restorePersistedState(config, {
      participantScores: { w1: 4, w2: 1 },
      assignment: { w1: "red", w2: "green" },
      clocksByPhase: {
        period_1: { remainingSeconds: 30 }
      },
      timers: {
        w1: {
          injury: { remainingSeconds: 50 }
        }
      }
    })

    expect(restored.participantScores).toEqual({ w1: 4, w2: 1 })
    expect(restored.assignment).toEqual({ w1: "red", w2: "green" })
    expect(restored.clocksByPhase.period_1.remainingSeconds).toBe(30)
    expect(restored.clocksByPhase.period_1.durationSeconds).toBe(120)
    expect(restored.timers.w1.injury.remainingSeconds).toBe(50)
    expect(restored.timers.w2.injury.remainingSeconds).toBe(90)
  })
})
