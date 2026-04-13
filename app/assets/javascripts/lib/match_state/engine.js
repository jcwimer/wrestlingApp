export function buildTimerState(config) {
  return Object.fromEntries(
    Object.entries(config.timers).map(([timerKey, timerConfig]) => [
      timerKey,
      {
        remainingSeconds: timerConfig.maxSeconds,
        running: false,
        startedAt: null
      }
    ])
  )
}

export function buildClockState(config) {
  return Object.fromEntries(
    config.phaseSequence
      .filter((phase) => phase.type === "period")
      .map((phase) => [
        phase.key,
        {
          durationSeconds: phase.clockSeconds,
          remainingSeconds: phase.clockSeconds,
          running: false,
          startedAt: null
        }
      ])
  )
}

export function buildInitialState(config) {
  const openingPhase = config.phaseSequence[0]

  return {
    participantScores: {
      w1: 0,
      w2: 0
    },
    control: "neutral",
    displayControl: "neutral",
    phaseIndex: 0,
    selections: {},
    assignment: {
      w1: "green",
      w2: "red"
    },
    nextEventId: 1,
    nextEventGroupId: 1,
    events: [],
    clocksByPhase: buildClockState(config),
    clock: {
      durationSeconds: openingPhase.clockSeconds,
      remainingSeconds: openingPhase.clockSeconds,
      running: false,
      startedAt: null
    },
    timers: {
      w1: buildTimerState(config),
      w2: buildTimerState(config)
    }
  }
}

export function buildEvent(state, phase, clockSeconds, participantKey, actionKey, options = {}) {
  return {
    id: state.nextEventId++,
    phaseKey: phase.key,
    phaseLabel: phase.label,
    clockSeconds,
    participantKey,
    actionKey,
    actionGroupId: options.actionGroupId
  }
}

export function opponentParticipant(participantKey) {
  return participantKey === "w1" ? "w2" : "w1"
}

export function isProgressiveAction(config, actionKey) {
  return Object.prototype.hasOwnProperty.call(config.progressionRules || {}, actionKey)
}

export function progressiveActionCountForParticipant(events, participantKey, actionKey) {
  return events.filter((eventRecord) =>
    eventRecord.participantKey === participantKey && eventRecord.actionKey === actionKey
  ).length
}

export function progressiveActionPointsForOffense(config, actionKey, offenseNumber) {
  const progression = config.progressionRules?.[actionKey] || []
  return progression[Math.min(offenseNumber - 1, progression.length - 1)] || 0
}

export function recordProgressiveAction(config, state, participantKey, actionKey, buildEvent) {
  const offenseNumber = progressiveActionCountForParticipant(state.events, participantKey, actionKey) + 1
  const actionGroupId = state.nextEventGroupId++
  state.events.push(buildEvent(participantKey, actionKey, { actionGroupId }))

  const awardedPoints = progressiveActionPointsForOffense(config, actionKey, offenseNumber)
  if (awardedPoints > 0) {
    state.events.push(buildEvent(opponentParticipant(participantKey), `plus_${awardedPoints}`, { actionGroupId }))
  }
}

export function applyMatchAction(config, state, phase, clockSeconds, participantKey, actionKey) {
  const effect = config.actionEffects[actionKey]
  if (!effect) return false

  if (isProgressiveAction(config, actionKey)) {
    recordProgressiveAction(
      config,
      state,
      participantKey,
      actionKey,
      (eventParticipantKey, eventActionKey, options = {}) =>
        buildEvent(state, phase, clockSeconds, eventParticipantKey, eventActionKey, options)
    )
  } else {
    state.events.push(buildEvent(state, phase, clockSeconds, participantKey, actionKey))
  }

  return true
}

export function applyChoiceAction(state, phase, clockSeconds, participantKey, choiceKey) {
  if (phase.type !== "choice") return { applied: false, deferred: false }

  state.events.push(buildEvent(state, phase, clockSeconds, participantKey, `choice_${choiceKey}`))

  if (choiceKey === "defer") {
    return { applied: true, deferred: true }
  }

  state.selections[phase.key] = {
    participantKey,
    choiceKey
  }

  return { applied: true, deferred: false }
}

export function deleteEventFromState(config, state, eventId) {
  const eventRecord = state.events.find((eventItem) => eventItem.id === eventId)
  if (!eventRecord) return false

  let eventIdsToDelete = [eventId]

  if (eventRecord.actionKey.startsWith("timer_used_") && typeof eventRecord.elapsedSeconds === "number") {
    const timerKey = eventRecord.actionKey.replace("timer_used_", "")
    const timer = state.timers[eventRecord.participantKey]?.[timerKey]
    const maxSeconds = config.timers[timerKey]?.maxSeconds || 0
    if (timer) {
      timer.remainingSeconds = Math.min(maxSeconds, timer.remainingSeconds + eventRecord.elapsedSeconds)
    }
  }

  if (isProgressiveAction(config, eventRecord.actionKey)) {
    const linkedAward = findLinkedProgressiveAward(state.events, eventRecord)
    if (linkedAward) {
      eventIdsToDelete.push(linkedAward.id)
    }
  }

  state.events = state.events.filter((eventItem) => !eventIdsToDelete.includes(eventItem.id))
  return true
}

export function swapEventParticipants(config, state, eventId) {
  const eventRecord = state.events.find((eventItem) => eventItem.id === eventId)
  if (!eventRecord) return false

  const originalParticipant = eventRecord.participantKey
  const swappedParticipant = opponentParticipant(originalParticipant)

  if (eventRecord.actionKey.startsWith("timer_used_") && typeof eventRecord.elapsedSeconds === "number") {
    reassignTimerUsage(config, state, eventRecord, swappedParticipant)
  }

  eventRecord.participantKey = swappedParticipant

  if (isProgressiveAction(config, eventRecord.actionKey)) {
    swapLinkedProgressiveAward(state.events, eventRecord, swappedParticipant)
  }

  return true
}

export function swapPhaseParticipants(config, state, phaseKey) {
  const phaseEvents = state.events.filter((eventRecord) => eventRecord.phaseKey === phaseKey)
  if (phaseEvents.length === 0) return false

  phaseEvents.forEach((eventRecord) => {
    if (eventRecord.actionKey.startsWith("timer_used_") && typeof eventRecord.elapsedSeconds === "number") {
      reassignTimerUsage(config, state, eventRecord, opponentParticipant(eventRecord.participantKey))
    }

    eventRecord.participantKey = opponentParticipant(eventRecord.participantKey)
  })

  return true
}

export function phaseIndexForKey(config, phaseKey) {
  const phaseIndex = config.phaseSequence.findIndex((phase) => phase.key === phaseKey)
  return phaseIndex === -1 ? Number.MAX_SAFE_INTEGER : phaseIndex
}

export function activeClockForPhase(state, phase) {
  if (!phase || phase.type !== "period") return null
  return state.clocksByPhase[phase.key] || null
}

export function hasRunningClockOrTimer(state) {
  const anyTimerRunning = ["w1", "w2"].some((participantKey) =>
    Object.values(state.timers[participantKey] || {}).some((timer) => timer.running)
  )
  const anyClockRunning = Object.values(state.clocksByPhase || {}).some((clock) => clock.running)
  return anyTimerRunning || anyClockRunning
}

export function stopAllAuxiliaryTimers(state, now = Date.now()) {
  for (const participantKey of ["w1", "w2"]) {
    for (const timerKey of Object.keys(state.timers[participantKey] || {})) {
      const timer = state.timers[participantKey][timerKey]
      if (!timer.running) continue

      const elapsedSeconds = Math.floor((now - timer.startedAt) / 1000)
      timer.remainingSeconds = Math.max(0, timer.remainingSeconds - elapsedSeconds)
      timer.running = false
      timer.startedAt = null
    }
  }
}

export function moveToPreviousPhase(config, state) {
  if (state.phaseIndex === 0) return false
  state.phaseIndex -= 1
  state.control = baseControlForPhase(config.phaseSequence[state.phaseIndex], state.selections, state.control)
  return true
}

export function moveToNextPhase(config, state) {
  if (state.phaseIndex >= config.phaseSequence.length - 1) return false
  state.phaseIndex += 1
  state.control = baseControlForPhase(config.phaseSequence[state.phaseIndex], state.selections, state.control)
  return true
}

export function orderedEvents(config, events) {
  return [...events].sort((leftEvent, rightEvent) => {
    const leftPhaseIndex = phaseIndexForKey(config, leftEvent.phaseKey)
    const rightPhaseIndex = phaseIndexForKey(config, rightEvent.phaseKey)
    if (leftPhaseIndex !== rightPhaseIndex) {
      return leftPhaseIndex - rightPhaseIndex
    }
    return leftEvent.id - rightEvent.id
  })
}

export function controlFromChoice(selection) {
  if (!selection) return "neutral"
  if (selection.choiceKey === "neutral" || selection.choiceKey === "defer") return "neutral"
  if (selection.choiceKey === "top") return `${selection.participantKey}_control`
  if (selection.choiceKey === "bottom") return `${opponentParticipant(selection.participantKey)}_control`
  return "neutral"
}

export function baseControlForPhase(phase, selections, fallbackControl) {
  if (phase.type !== "period") return fallbackControl
  if (phase.startsIn === "neutral") return "neutral"
  if (phase.startsFromChoice) {
    return controlFromChoice(selections[phase.startsFromChoice])
  }
  return "neutral"
}

export function recomputeDerivedState(config, state) {
  state.participantScores = { w1: 0, w2: 0 }
  state.selections = {}
  state.control = baseControlForPhase(config.phaseSequence[state.phaseIndex], state.selections, state.control)

  orderedEvents(config, state.events).forEach((eventRecord) => {
    if (eventRecord.actionKey.startsWith("choice_")) {
      const choiceKey = eventRecord.actionKey.replace("choice_", "")
      if (choiceKey === "defer") return

      state.selections[eventRecord.phaseKey] = {
        participantKey: eventRecord.participantKey,
        choiceKey: choiceKey
      }
      state.control = baseControlForPhase(config.phaseSequence[state.phaseIndex], state.selections, state.control)
      return
    }

    const effect = config.actionEffects[eventRecord.actionKey]
    if (!effect) return

    const scoringParticipant = effect.target === "opponent"
      ? opponentParticipant(eventRecord.participantKey)
      : eventRecord.participantKey
    const nextScore = state.participantScores[scoringParticipant] + effect.points
    state.participantScores[scoringParticipant] = Math.max(0, nextScore)

    if (effect.nextPosition === "neutral") {
      state.control = "neutral"
    } else if (effect.nextPosition === "top") {
      state.control = `${eventRecord.participantKey}_control`
    } else if (effect.nextPosition === "bottom") {
      state.control = `${opponentParticipant(eventRecord.participantKey)}_control`
    }
  })

  state.displayControl = controlForSelectedPhase(config, state)
}

export function controlForSelectedPhase(config, state) {
  const selectedPhase = config.phaseSequence[state.phaseIndex]
  let control = baseControlForPhase(selectedPhase, state.selections, state.control)
  const selectedPhaseIndex = phaseIndexForKey(config, selectedPhase.key)

  orderedEvents(config, state.events).forEach((eventRecord) => {
    if (phaseIndexForKey(config, eventRecord.phaseKey) > selectedPhaseIndex) return
    if (eventRecord.phaseKey !== selectedPhase.key) return

    const effect = config.actionEffects[eventRecord.actionKey]
    if (!effect) return

    if (effect.nextPosition === "neutral") {
      control = "neutral"
    } else if (effect.nextPosition === "top") {
      control = `${eventRecord.participantKey}_control`
    } else if (effect.nextPosition === "bottom") {
      control = `${opponentParticipant(eventRecord.participantKey)}_control`
    }
  })

  return control
}

export function currentClockSeconds(clockState, now = Date.now()) {
  if (!clockState) return 0
  if (!clockState.running || !clockState.startedAt) {
    return clockState.remainingSeconds
  }

  const elapsedSeconds = Math.floor((now - clockState.startedAt) / 1000)
  return Math.max(0, clockState.remainingSeconds - elapsedSeconds)
}

export function currentAuxiliaryTimerSeconds(timerState, now = Date.now()) {
  if (!timerState) return 0
  if (!timerState.running || !timerState.startedAt) {
    return timerState.remainingSeconds
  }

  const elapsedSeconds = Math.floor((now - timerState.startedAt) / 1000)
  return Math.max(0, timerState.remainingSeconds - elapsedSeconds)
}

export function syncClockSnapshot(activeClock) {
  if (!activeClock) {
    return {
      durationSeconds: 0,
      remainingSeconds: 0,
      running: false,
      startedAt: null
    }
  }

  return {
    durationSeconds: activeClock.durationSeconds,
    remainingSeconds: activeClock.remainingSeconds,
    running: activeClock.running,
    startedAt: activeClock.startedAt
  }
}

export function startClockState(activeClock, now = Date.now()) {
  if (!activeClock || activeClock.running) return false
  activeClock.running = true
  activeClock.startedAt = now
  return true
}

export function stopClockState(activeClock, now = Date.now()) {
  if (!activeClock || !activeClock.running) return false
  activeClock.remainingSeconds = currentClockSeconds(activeClock, now)
  activeClock.running = false
  activeClock.startedAt = null
  return true
}

export function adjustClockState(activeClock, deltaSeconds, now = Date.now()) {
  if (!activeClock) return false

  const currentSeconds = currentClockSeconds(activeClock, now)
  activeClock.remainingSeconds = Math.max(0, currentSeconds + deltaSeconds)
  if (activeClock.running) {
    activeClock.startedAt = now
  }

  return true
}

export function startAuxiliaryTimerState(timerState, now = Date.now()) {
  if (!timerState || timerState.running) return false
  timerState.running = true
  timerState.startedAt = now
  return true
}

export function stopAuxiliaryTimerState(timerState, now = Date.now()) {
  if (!timerState || !timerState.running) return { stopped: false, elapsedSeconds: 0 }

  const elapsedSeconds = Math.floor((now - timerState.startedAt) / 1000)
  timerState.remainingSeconds = currentAuxiliaryTimerSeconds(timerState, now)
  timerState.running = false
  timerState.startedAt = null

  return { stopped: true, elapsedSeconds }
}

export function accumulatedMatchSeconds(config, state, activePhaseKey, now = Date.now()) {
  return config.phaseSequence
    .filter((phase) => phase.type === "period")
    .reduce((totalElapsed, phase) => {
      const clockState = state.clocksByPhase[phase.key]
      if (!clockState) return totalElapsed

      const remainingSeconds = phase.key === activePhaseKey
        ? currentClockSeconds(clockState, now)
        : clockState.remainingSeconds

      const elapsedSeconds = Math.max(0, clockState.durationSeconds - remainingSeconds)
      return totalElapsed + elapsedSeconds
    }, 0)
}

export function derivedStats(config, events) {
  const grouped = config.phaseSequence.map((phase) => {
    const phaseEvents = orderedEvents(config, events).filter((eventRecord) => eventRecord.phaseKey === phase.key)
    if (phaseEvents.length === 0) return null

    return {
      label: phase.label,
      w1: phaseEvents
        .filter((eventRecord) => eventRecord.participantKey === "w1")
        .map((eventRecord) => statTextForEvent(config, eventRecord))
        .filter(Boolean),
      w2: phaseEvents
        .filter((eventRecord) => eventRecord.participantKey === "w2")
        .map((eventRecord) => statTextForEvent(config, eventRecord))
        .filter(Boolean)
    }
  }).filter(Boolean)

  return {
    w1: formatStatsByPhase(grouped, "w1"),
    w2: formatStatsByPhase(grouped, "w2")
  }
}

export function scoreboardStatePayload(config, state, metadata) {
  return {
    participantScores: state.participantScores,
    assignment: state.assignment,
    phaseIndex: state.phaseIndex,
    clocksByPhase: state.clocksByPhase,
    timers: state.timers,
    metadata: metadata,
    matchResult: {
      finished: false
    }
  }
}

export function matchResultDefaults(state, options = {}) {
  const {
    w1Id = "",
    w2Id = "",
    currentPhase = {},
    accumulationSeconds = 0
  } = options

  const w1Score = state.participantScores.w1
  const w2Score = state.participantScores.w2
  let winnerId = ""
  let winnerScore = w1Score
  let loserScore = w2Score

  if (w1Score > w2Score) {
    winnerId = w1Id || ""
    winnerScore = w1Score
    loserScore = w2Score
  } else if (w2Score > w1Score) {
    winnerId = w2Id || ""
    winnerScore = w2Score
    loserScore = w1Score
  }

  return {
    winnerId,
    overtimeType: currentPhase.overtimeType || "",
    winnerScore,
    loserScore,
    pinMinutes: Math.floor(accumulationSeconds / 60),
    pinSeconds: accumulationSeconds % 60
  }
}

function statTextForEvent(config, eventRecord) {
  if (eventRecord.actionKey.startsWith("timer_used_")) {
    const timerKey = eventRecord.actionKey.replace("timer_used_", "")
    const timerConfig = config.timers[timerKey]
    if (!timerConfig || typeof eventRecord.elapsedSeconds !== "number") return null
    return `${timerConfig.statCode || timerConfig.label}: ${formatClock(eventRecord.elapsedSeconds)}`
  }

  const action = config.actionsByKey[eventRecord.actionKey]
  return action?.statCode || null
}

function formatStatsByPhase(groupedPhases, participantKey) {
  return groupedPhases
    .map((phase) => {
      const items = phase[participantKey]
      if (!items || items.length === 0) return null
      return `${phase.label}: ${items.join(" ")}`
    })
    .filter(Boolean)
    .join("\n")
}

function formatClock(totalSeconds) {
  const minutes = Math.floor(totalSeconds / 60)
  const seconds = totalSeconds % 60
  return `${minutes}:${seconds.toString().padStart(2, "0")}`
}

function reassignTimerUsage(config, state, eventRecord, newParticipantKey) {
  const timerKey = eventRecord.actionKey.replace("timer_used_", "")
  const originalParticipant = eventRecord.participantKey
  const originalTimer = state.timers[originalParticipant]?.[timerKey]
  const newTimer = state.timers[newParticipantKey]?.[timerKey]
  const maxSeconds = config.timers[timerKey]?.maxSeconds || 0

  if (!originalTimer || !newTimer || typeof eventRecord.elapsedSeconds !== "number") return

  originalTimer.remainingSeconds = Math.min(maxSeconds, originalTimer.remainingSeconds + eventRecord.elapsedSeconds)
  newTimer.remainingSeconds = Math.max(0, newTimer.remainingSeconds - eventRecord.elapsedSeconds)
}

function swapLinkedProgressiveAward(events, eventRecord, offendingParticipant) {
  const linkedAward = findLinkedProgressiveAward(events, eventRecord)
  if (linkedAward) {
    linkedAward.participantKey = opponentParticipant(offendingParticipant)
  }
}

function findLinkedProgressiveAward(events, eventRecord) {
  return events.find((candidateEvent) =>
    candidateEvent.id !== eventRecord.id &&
    candidateEvent.actionGroupId &&
    candidateEvent.actionGroupId === eventRecord.actionGroupId &&
    candidateEvent.actionKey.startsWith("plus_")
  )
}
