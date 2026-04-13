import { buildInitialState } from "match-state-engine"

export function buildMatchMetadata(values) {
  return {
    tournamentId: values.tournamentId,
    boutNumber: values.boutNumber,
    weightLabel: values.weightLabel,
    ruleset: values.ruleset,
    bracketPosition: values.bracketPosition,
    w1Name: values.w1Name,
    w2Name: values.w2Name,
    w1School: values.w1School,
    w2School: values.w2School
  }
}

export function buildStorageKey(tournamentId, boutNumber) {
  return `match-state:${tournamentId}:${boutNumber}`
}

export function buildPersistedState(state, metadata) {
  return {
    ...state,
    metadata
  }
}

export function restorePersistedState(config, parsedState) {
  const initialState = buildInitialState(config)

  return {
    ...initialState,
    ...parsedState,
    participantScores: {
      ...initialState.participantScores,
      ...(parsedState.participantScores || {})
    },
    assignment: {
      ...initialState.assignment,
      ...(parsedState.assignment || {})
    },
    clock: {
      ...initialState.clock,
      ...(parsedState.clock || {})
    },
    timers: {
      w1: {
        ...initialState.timers.w1,
        ...(parsedState.timers?.w1 || {})
      },
      w2: {
        ...initialState.timers.w2,
        ...(parsedState.timers?.w2 || {})
      }
    },
    clocksByPhase: Object.fromEntries(
      Object.entries(initialState.clocksByPhase).map(([phaseKey, defaultClock]) => [
        phaseKey,
        {
          ...defaultClock,
          ...(parsedState.clocksByPhase?.[phaseKey] || {})
        }
      ])
    )
  }
}
