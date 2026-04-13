export function participantForColor(state, color) {
  if (!state?.assignment) {
    return color === "red" ? "w2" : "w1"
  }

  const match = Object.entries(state.assignment).find(([, assignedColor]) => assignedColor === color)
  return match ? match[0] : (color === "red" ? "w2" : "w1")
}

export function participantColor(state, participantKey) {
  return state?.assignment?.[participantKey] || (participantKey === "w1" ? "green" : "red")
}

export function participantName(state, participantKey) {
  return participantKey === "w1" ? state?.metadata?.w1Name : state?.metadata?.w2Name
}

export function participantSchool(state, participantKey) {
  return participantKey === "w1" ? state?.metadata?.w1School : state?.metadata?.w2School
}

export function participantScore(state, participantKey) {
  return state?.participantScores?.[participantKey] || 0
}

export function currentPhaseLabel(config, state) {
  const phaseIndex = state?.phaseIndex || 0
  return config?.phaseSequence?.[phaseIndex]?.label || "Period 1"
}

export function currentClockText(config, state, formatClock, now = Date.now()) {
  const phaseIndex = state?.phaseIndex || 0
  const phase = config?.phaseSequence?.[phaseIndex]
  if (!phase || phase.type !== "period") return "-"

  const clockState = state?.clocksByPhase?.[phase.key]
  if (!clockState) return formatClock(phase.clockSeconds)

  let remainingSeconds = clockState.remainingSeconds
  if (clockState.running && clockState.startedAt) {
    const elapsedSeconds = Math.floor((now - clockState.startedAt) / 1000)
    remainingSeconds = Math.max(0, clockState.remainingSeconds - elapsedSeconds)
  }

  return formatClock(remainingSeconds)
}

export function currentAuxiliaryTimerSeconds(state, participantKey, timerKey, now = Date.now()) {
  const timer = state?.timers?.[participantKey]?.[timerKey]
  if (!timer) return 0
  if (!timer.running || !timer.startedAt) {
    return timer.remainingSeconds
  }

  const elapsedSeconds = Math.floor((now - timer.startedAt) / 1000)
  return Math.max(0, timer.remainingSeconds - elapsedSeconds)
}

export function runningTimerForParticipant(state, participantKey) {
  for (const timerKey of Object.keys(state?.timers?.[participantKey] || {})) {
    if (state.timers[participantKey][timerKey]?.running) {
      return timerKey
    }
  }
  return null
}

export function participantDisplayLabel(state, participantKey) {
  return `${participantForColor(state, "red") === participantKey ? "Red" : "Green"} ${participantName(state, participantKey)}`
}

export function timerIndicatorLabel(config, state, participantKey, formatClock, now = Date.now()) {
  const runningTimer = runningTimerForParticipant(state, participantKey)
  if (!runningTimer) return ""

  const timerConfig = config?.timers?.[runningTimer]
  if (!timerConfig) return ""

  const remainingSeconds = currentAuxiliaryTimerSeconds(state, participantKey, runningTimer, now)
  const usedSeconds = Math.max(0, timerConfig.maxSeconds - remainingSeconds)
  return `${timerConfig.label}: ${formatClock(usedSeconds)}`
}

export function buildRunningTimerSnapshot(state) {
  const snapshot = {}
  for (const participantKey of ["w1", "w2"]) {
    for (const timerKey of Object.keys(state?.timers?.[participantKey] || {})) {
      const timer = state.timers[participantKey][timerKey]
      snapshot[`${participantKey}:${timerKey}`] = Boolean(timer?.running)
    }
  }
  return snapshot
}

export function detectRecentlyStoppedTimer(state, previousTimerSnapshot) {
  previousTimerSnapshot ||= {}

  for (const participantKey of ["w1", "w2"]) {
    for (const timerKey of Object.keys(state?.timers?.[participantKey] || {})) {
      const snapshotKey = `${participantKey}:${timerKey}`
      const wasRunning = previousTimerSnapshot[snapshotKey]
      const isRunning = Boolean(state.timers[participantKey][timerKey]?.running)
      if (wasRunning && !isRunning) {
        return { participantKey, timerKey }
      }
    }
  }
  return null
}

export function runningAuxiliaryTimer(state) {
  for (const participantKey of ["w1", "w2"]) {
    for (const timerKey of Object.keys(state?.timers?.[participantKey] || {})) {
      const timer = state.timers[participantKey][timerKey]
      if (timer?.running) {
        return { participantKey, timerKey }
      }
    }
  }
  return null
}

export function mainClockRunning(config, state) {
  const phaseIndex = state?.phaseIndex || 0
  const phase = config?.phaseSequence?.[phaseIndex]
  if (!phase || phase.type !== "period") return false
  return Boolean(state?.clocksByPhase?.[phase.key]?.running)
}

export function timerBannerViewModel(config, state, timerBannerState, formatClock, now = Date.now()) {
  if (!timerBannerState) return null

  const { participantKey, timerKey, expiresAt } = timerBannerState
  if (expiresAt && now > expiresAt) return null

  const timer = state?.timers?.[participantKey]?.[timerKey]
  const timerConfig = config?.timers?.[timerKey]
  if (!timer || !timerConfig) return null

  const runningSeconds = currentAuxiliaryTimerSeconds(state, participantKey, timerKey, now)
  const usedSeconds = Math.max(0, timerConfig.maxSeconds - runningSeconds)
  const color = participantColor(state, participantKey)
  const label = `${participantDisplayLabel(state, participantKey)} ${timerConfig.label}`

  return {
    color,
    label: timer.running ? `${label} Running` : `${label} Used`,
    clockText: formatClock(usedSeconds)
  }
}

export function populatedBoardViewModel(config, state, liveMatchData, currentBoutNumber, formatClock, now = Date.now()) {
  const redParticipant = participantForColor(state, "red")
  const greenParticipant = participantForColor(state, "green")

  return {
    isEmpty: false,
    redName: participantName(state, redParticipant),
    redSchool: participantSchool(state, redParticipant),
    redScore: participantScore(state, redParticipant).toString(),
    redTimerIndicator: timerIndicatorLabel(config, state, redParticipant, formatClock, now),
    greenName: participantName(state, greenParticipant),
    greenSchool: participantSchool(state, greenParticipant),
    greenScore: participantScore(state, greenParticipant).toString(),
    greenTimerIndicator: timerIndicatorLabel(config, state, greenParticipant, formatClock, now),
    clockText: currentClockText(config, state, formatClock, now),
    phaseLabel: currentPhaseLabel(config, state),
    weightLabel: state?.metadata?.weightLabel ? `Weight ${state.metadata.weightLabel}` : "Weight -",
    boutLabel: currentBoutNumber ? `Bout ${currentBoutNumber}` : "No Bout",
    redStats: redParticipant === "w1" ? (liveMatchData?.w1_stat || "") : (liveMatchData?.w2_stat || ""),
    greenStats: greenParticipant === "w1" ? (liveMatchData?.w1_stat || "") : (liveMatchData?.w2_stat || "")
  }
}

export function emptyBoardViewModel(currentBoutNumber, lastMatchResult) {
  return {
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
    boutLabel: currentBoutNumber ? `Bout ${currentBoutNumber}` : "No Bout",
    redStats: "",
    greenStats: "",
    lastMatchResult: lastMatchResult || "-"
  }
}

export function nextTimerBannerState(state, previousTimerSnapshot, now = Date.now()) {
  if (!state?.timers) {
    return { timerBannerState: null, previousTimerSnapshot: {} }
  }

  const activeTimer = runningAuxiliaryTimer(state)
  const nextSnapshot = buildRunningTimerSnapshot(state)

  if (activeTimer) {
    return {
      timerBannerState: {
        participantKey: activeTimer.participantKey,
        timerKey: activeTimer.timerKey,
        expiresAt: null
      },
      previousTimerSnapshot: nextSnapshot
    }
  }

  const stoppedTimer = detectRecentlyStoppedTimer(state, previousTimerSnapshot)
  if (stoppedTimer) {
    return {
      timerBannerState: {
        participantKey: stoppedTimer.participantKey,
        timerKey: stoppedTimer.timerKey,
        expiresAt: now + 10000
      },
      previousTimerSnapshot: nextSnapshot
    }
  }

  return {
    timerBannerState: null,
    previousTimerSnapshot: nextSnapshot
  }
}

export function boardColors(isEmpty) {
  if (isEmpty) {
    return {
      red: "#000",
      center: "#000",
      green: "#000"
    }
  }

  return {
    red: "#c91f1f",
    center: "#050505",
    green: "#1cab2d"
  }
}

export function timerBannerRenderState(config, state, timerBannerState, formatClock, now = Date.now()) {
  if (mainClockRunning(config, state)) {
    return {
      timerBannerState: timerBannerState?.expiresAt ? null : timerBannerState,
      visible: false,
      viewModel: null
    }
  }

  if (!timerBannerState) {
    return {
      timerBannerState: null,
      visible: false,
      viewModel: null
    }
  }

  if (timerBannerState.expiresAt && now > timerBannerState.expiresAt) {
    return {
      timerBannerState: null,
      visible: false,
      viewModel: null
    }
  }

  const viewModel = timerBannerViewModel(config, state, timerBannerState, formatClock, now)
  if (!viewModel) {
    return {
      timerBannerState,
      visible: false,
      viewModel: null
    }
  }

  return {
    timerBannerState,
    visible: true,
    viewModel
  }
}
