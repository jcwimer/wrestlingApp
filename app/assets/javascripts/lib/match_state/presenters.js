import { orderedEvents } from "match-state-engine"

export function displayLabelForParticipant(assignment, participantKey) {
  return assignment[participantKey] === "green" ? "Green" : "Red"
}

export function buttonClassForParticipant(assignment, participantKey) {
  return assignment[participantKey] === "green" ? "btn-success" : "btn-danger"
}

export function humanizeChoice(choiceKey) {
  if (choiceKey === "top") return "Top"
  if (choiceKey === "bottom") return "Bottom"
  if (choiceKey === "neutral") return "Neutral"
  if (choiceKey === "defer") return "Defer"
  return choiceKey
}

export function choiceLabelForPhase(phase) {
  if (phase.chooser === "other") return "Other wrestler chooses"
  return "Choose wrestler and position"
}

export function eventLogSections(config, state, formatClock) {
  const eventsByPhase = orderedEvents(config, state.events).reduce((accumulator, eventRecord) => {
    if (!accumulator[eventRecord.phaseKey]) {
      accumulator[eventRecord.phaseKey] = []
    }
    accumulator[eventRecord.phaseKey].push(eventRecord)
    return accumulator
  }, {})

  return config.phaseSequence.map((phase) => {
    const phaseEvents = eventsByPhase[phase.key]
    if (!phaseEvents || phaseEvents.length === 0) return null

    return {
      key: phase.key,
      label: phase.label,
      items: [...phaseEvents].reverse().map((eventRecord) => ({
        id: eventRecord.id,
        participantKey: eventRecord.participantKey,
        colorLabel: displayLabelForParticipant(state.assignment, eventRecord.participantKey),
        actionLabel: eventActionLabel(config, eventRecord, formatClock),
        clockLabel: formatClock(eventRecord.clockSeconds)
      }))
    }
  }).filter(Boolean)
}

export function choiceViewModel(config, state, phase, participantMeta) {
  if (phase.type !== "choice") return null

  const phaseEvents = state.events.filter((eventRecord) => eventRecord.phaseKey === phase.key)
  const deferredParticipants = phaseEvents
    .filter((eventRecord) => eventRecord.actionKey === "choice_defer")
    .map((eventRecord) => eventRecord.participantKey)
  const selection = state.selections[phase.key]

  const selectionText = selection
    ? `Selected: ${displayLabelForParticipant(state.assignment, selection.participantKey)} ${humanizeChoice(selection.choiceKey)}`
    : deferredParticipants.length > 0
      ? `${deferredParticipants.map((participantKey) => displayLabelForParticipant(state.assignment, participantKey)).join(", ")} deferred. Waiting for the other wrestler to choose.`
      : "No choice selected."

  const availableParticipants = deferredParticipants.length > 0
    ? ["w1", "w2"].filter((participantKey) => !deferredParticipants.includes(participantKey))
    : ["w1", "w2"]

  const buttons = availableParticipants.flatMap((participantKey) =>
    phase.options
      .filter((choiceKey) => !(deferredParticipants.length > 0 && choiceKey === "defer"))
      .map((choiceKey) => ({
        participantKey,
        choiceKey,
        buttonClass: buttonClassForParticipant(state.assignment, participantKey),
        text: `${participantMeta[participantKey].name} (${displayLabelForParticipant(state.assignment, participantKey)}) ${humanizeChoice(choiceKey)}`
      }))
  )

  return {
    label: choiceLabelForPhase(phase),
    selectionText,
    buttons
  }
}

function eventActionLabel(config, eventRecord, formatClock) {
  let actionLabel = config.actionLabels[eventRecord.actionKey] || eventRecord.actionKey
  if (eventRecord.actionKey.startsWith("timer_used_") && typeof eventRecord.elapsedSeconds === "number") {
    actionLabel = `${actionLabel}: ${formatClock(eventRecord.elapsedSeconds)}`
  }
  return actionLabel
}
