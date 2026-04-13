import { buildStorageKey } from "match-state-serializers"

export function buildScoreboardContext({ initialBoutNumber, matchId }) {
  const currentQueueBoutNumber = initialBoutNumber > 0 ? initialBoutNumber : null

  return {
    currentQueueBoutNumber,
    currentBoutNumber: currentQueueBoutNumber,
    currentMatchId: matchId || null,
    liveMatchData: {},
    lastMatchResult: "",
    state: null,
    finished: false,
    timerBannerState: null,
    previousTimerSnapshot: {}
  }
}

export function selectedBoutStorageKey(tournamentId, matId) {
  return `mat-selected-bout:${tournamentId}:${matId}`
}

export function matchStorageKey(tournamentId, boutNumber) {
  if (!boutNumber) return null
  return buildStorageKey(tournamentId, boutNumber)
}

export function extractLiveMatchData(data) {
  const extracted = {}
  if (data.w1_stat !== undefined) extracted.w1_stat = data.w1_stat
  if (data.w2_stat !== undefined) extracted.w2_stat = data.w2_stat
  if (data.score !== undefined) extracted.score = data.score
  if (data.win_type !== undefined) extracted.win_type = data.win_type
  if (data.winner_name !== undefined) extracted.winner_name = data.winner_name
  if (data.finished !== undefined) extracted.finished = data.finished
  return extracted
}

export function applyStatePayloadContext(currentContext, payload) {
  return {
    ...currentContext,
    state: payload,
    finished: Boolean(payload?.matchResult?.finished),
    currentBoutNumber: payload?.metadata?.boutNumber || currentContext.currentBoutNumber
  }
}

export function applyMatchPayloadContext(currentContext, data) {
  const nextContext = { ...currentContext }

  if (data.scoreboard_state) {
    Object.assign(nextContext, applyStatePayloadContext(nextContext, data.scoreboard_state))
  }

  nextContext.liveMatchData = {
    ...currentContext.liveMatchData,
    ...extractLiveMatchData(data)
  }

  if (data.finished !== undefined) {
    nextContext.finished = Boolean(data.finished)
  }

  return nextContext
}

export function applyMatPayloadContext(currentContext, data) {
  const currentQueueBoutNumber = data.queue1_bout_number || null
  const lastMatchResult = data.last_match_result || ""

  if (currentContext.sourceMode === "localstorage") {
    return {
      ...currentContext,
      currentQueueBoutNumber: data.selected_bout_number || currentQueueBoutNumber,
      lastMatchResult,
      loadSelectedBout: true,
      loadLocalState: true,
      unsubscribeMatch: false,
      subscribeMatchId: null,
      renderNow: true
    }
  }

  const nextMatchId = data.selected_match_id || data.queue1_match_id || null
  const nextBoutNumber = data.selected_bout_number || data.queue1_bout_number || null
  const matchChanged = nextMatchId !== currentContext.currentMatchId

  if (!nextMatchId) {
    return {
      ...currentContext,
      currentQueueBoutNumber,
      lastMatchResult,
      currentMatchId: null,
      currentBoutNumber: nextBoutNumber,
      state: null,
      liveMatchData: {},
      resetTimerBanner: true,
      unsubscribeMatch: true,
      subscribeMatchId: null,
      renderNow: true
    }
  }

  return {
    ...currentContext,
    currentQueueBoutNumber,
    lastMatchResult,
    currentMatchId: nextMatchId,
    currentBoutNumber: nextBoutNumber,
    state: matchChanged ? null : currentContext.state,
    liveMatchData: matchChanged ? {} : currentContext.liveMatchData,
    resetTimerBanner: matchChanged,
    unsubscribeMatch: false,
    subscribeMatchId: matchChanged ? nextMatchId : null,
    renderNow: matchChanged
  }
}

export function connectionPlan(sourceMode, currentMatchId) {
  return {
    useStorageListener: sourceMode === "localstorage",
    subscribeMat: sourceMode === "localstorage" || sourceMode === "mat_websocket",
    subscribeMatch: sourceMode === "mat_websocket" || sourceMode === "websocket",
    matchId: sourceMode === "mat_websocket" || sourceMode === "websocket" ? currentMatchId : null,
    loadSelectedBout: sourceMode === "localstorage",
    loadLocalState: sourceMode === "localstorage"
  }
}

export function storageChangePlan(currentContext, eventKey, tournamentId, matId) {
  const selectedKey = selectedBoutStorageKey(tournamentId, matId)
  if (eventKey === selectedKey) {
    return {
      loadSelectedBout: true,
      loadLocalState: true,
      renderNow: true
    }
  }

  const storageKey = matchStorageKey(tournamentId, currentContext.currentBoutNumber)
  if (!storageKey || eventKey !== storageKey) {
    return {
      loadSelectedBout: false,
      loadLocalState: false,
      renderNow: false
    }
  }

  return {
    loadSelectedBout: false,
    loadLocalState: true,
    renderNow: true
  }
}

export function selectedBoutNumber(selection, currentQueueBoutNumber) {
  return selection?.boutNumber || currentQueueBoutNumber
}
