import { Controller } from "@hotwired/stimulus"
import { getMatchStateConfig } from "match-state-config"
import {
  accumulatedMatchSeconds as accumulatedMatchSecondsFromEngine,
  activeClockForPhase,
  adjustClockState,
  applyChoiceAction,
  applyMatchAction,
  baseControlForPhase,
  buildEvent as buildEventFromEngine,
  buildClockState,
  buildInitialState,
  buildTimerState,
  controlForSelectedPhase,
  controlFromChoice,
  currentAuxiliaryTimerSeconds as currentAuxiliaryTimerSecondsFromEngine,
  currentClockSeconds as currentClockSecondsFromEngine,
  deleteEventFromState,
  derivedStats as derivedStatsFromEngine,
  hasRunningClockOrTimer as hasRunningClockOrTimerFromEngine,
  matchResultDefaults as matchResultDefaultsFromEngine,
  moveToNextPhase,
  moveToPreviousPhase,
  orderedEvents as orderedEventsFromEngine,
  opponentParticipant as opponentParticipantFromEngine,
  phaseIndexForKey as phaseIndexForKeyFromEngine,
  recomputeDerivedState as recomputeDerivedStateFromEngine,
  scoreboardStatePayload as scoreboardStatePayloadFromEngine,
  startAuxiliaryTimerState,
  startClockState,
  stopAuxiliaryTimerState,
  stopClockState,
  stopAllAuxiliaryTimers as stopAllAuxiliaryTimersFromEngine,
  swapEventParticipants,
  swapPhaseParticipants,
  syncClockSnapshot
} from "match-state-engine"
import {
  buildMatchMetadata,
  buildPersistedState,
  buildStorageKey,
  restorePersistedState
} from "match-state-serializers"
import {
  loadJson,
  performIfChanged,
  removeKey,
  saveJson,
  MATCH_DATA_TTL_MS
} from "match-state-transport"
import {
  choiceViewModel,
  eventLogSections
} from "match-state-presenters"

export default class extends Controller {
  static targets = [
    "greenLabel",
    "redLabel",
    "greenPanel",
    "redPanel",
    "greenName",
    "redName",
    "greenSchool",
    "redSchool",
    "greenScore",
    "redScore",
    "periodLabel",
    "clock",
    "clockStatus",
    "accumulationClock",
    "matchPosition",
    "formatName",
    "choiceActions",
    "eventLog",
    "greenControls",
    "redControls",
    "matchResultsPanel",
    "w1StatField",
    "w2StatField"
  ]

  static values = {
    matchId: Number,
    tournamentId: Number,
    boutNumber: Number,
    weightLabel: String,
    bracketPosition: String,
    ruleset: String,
    w1Id: Number,
    w2Id: Number,
    w1Name: String,
    w2Name: String,
    w1School: String,
    w2School: String
  }

  connect() {
    this.config = getMatchStateConfig(this.rulesetValue, this.bracketPositionValue)
    this.boundHandleClick = this.handleDelegatedClick.bind(this)
    this.element.addEventListener("click", this.boundHandleClick)
    this.initializeState()
    this.loadPersistedState()
    this.syncClockFromActivePhase()
    if (this.hasRunningClockOrTimer()) {
      this.startTicking()
    }
    this.render({ rebuildControls: true })
    this.setupSubscription()
  }

  disconnect() {
    this.element.removeEventListener("click", this.boundHandleClick)
    window.clearTimeout(this.matchResultsDefaultsTimeout)
    this.cleanupSubscription()
    this.saveState()
    this.stopTicking()
    this.stopAllAuxiliaryTimers()
  }

  initializeState() {
    this.state = this.buildInitialState()
  }

  buildInitialState() {
    return buildInitialState(this.config)
  }

  render(options = {}) {
    const rebuildControls = options.rebuildControls === true
    if (this.hasGreenLabelTarget) this.greenLabelTarget.textContent = this.displayLabelForParticipant("w1")
    if (this.hasRedLabelTarget) this.redLabelTarget.textContent = this.displayLabelForParticipant("w2")
    if (this.hasGreenPanelTarget) this.applyPanelColor(this.greenPanelTarget, this.colorForParticipant("w1"))
    if (this.hasRedPanelTarget) this.applyPanelColor(this.redPanelTarget, this.colorForParticipant("w2"))
    if (this.hasGreenNameTarget) this.greenNameTarget.textContent = this.w1NameValue
    if (this.hasRedNameTarget) this.redNameTarget.textContent = this.w2NameValue
    if (this.hasGreenSchoolTarget) this.greenSchoolTarget.textContent = this.w1SchoolValue
    if (this.hasRedSchoolTarget) this.redSchoolTarget.textContent = this.w2SchoolValue
    if (this.hasGreenScoreTarget) this.greenScoreTarget.textContent = this.state.participantScores.w1.toString()
    if (this.hasRedScoreTarget) this.redScoreTarget.textContent = this.state.participantScores.w2.toString()
    if (this.hasPeriodLabelTarget) this.periodLabelTarget.textContent = this.currentPhase().label
    this.updateLiveDisplays()
    if (this.hasMatchPositionTarget) this.matchPositionTarget.textContent = this.humanizePosition(this.state.displayControl)
    if (this.hasFormatNameTarget) this.formatNameTarget.textContent = this.config.matchFormat.label
    if (rebuildControls) {
      if (this.hasGreenControlsTarget) this.greenControlsTarget.innerHTML = this.renderWrestlerControls("w1")
      if (this.hasRedControlsTarget) this.redControlsTarget.innerHTML = this.renderWrestlerControls("w2")
    }
    if (this.hasChoiceActionsTarget) this.choiceActionsTarget.innerHTML = this.renderChoiceActions()
    if (this.hasEventLogTarget) this.eventLogTarget.innerHTML = this.renderEventLog()
    this.updateTimerDisplays()
    this.updateStatFieldsAndBroadcast()
    this.scheduleApplyMatchResultDefaults()
    this.saveState()
  }

  renderWrestlerControls(participantKey) {
    return Object.values(this.config.wrestler_actions).map((section) => {
      const content = this.renderWrestlerSection(participantKey, section)
      if (!content) return ""

      return `
        <div style="margin-top: 12px;">
          <strong>${section.title}</strong>
          <div class="text-muted" style="margin: 4px 0 8px;">${section.description}</div>
          <div>${content}</div>
        </div>
      `
    }).join('<hr>')
  }

  renderWrestlerSection(participantKey, section) {
    if (!section) return ""

    if (section === this.config.wrestler_actions.timers) {
      return this.renderTimerSection(participantKey, section)
    }

    const actionKeys = this.actionKeysForSection(participantKey, section)
    return this.renderActionButtons(participantKey, actionKeys)
  }

  renderActionButtons(participantKey, actionKeys) {
    return actionKeys.map((actionKey) => {
      const action = this.config.actionsByKey[actionKey]
      if (!action) return ""

      const buttonClass = this.colorForParticipant(participantKey) === "green" ? "btn-success" : "btn-danger"
      return `<button type="button" class="btn ${buttonClass} btn-sm" data-match-state-button="score-action" data-participant-key="${participantKey}" data-action-key="${actionKey}">${action.label}</button>`
    }).join(" ")
  }

  actionKeysForSection(participantKey, section) {
    if (!section?.items) return []

    return section.items.flatMap((itemKey) => {
      if (itemKey === "global") {
        return this.availableActionKeysForAvailability(participantKey, "global")
      }

      if (itemKey === "position") {
        const position = this.positionForParticipant(participantKey)
        return this.availableActionKeysForAvailability(participantKey, position)
      }

      return itemKey
    })
  }

  availableActionKeysForAvailability(participantKey, availability) {
    if (this.currentPhase().type !== "period") return []

    return Object.entries(this.config.actionsByKey)
      .filter(([, action]) => action.availability === availability)
      .map(([actionKey]) => actionKey)
  }

  renderTimerSection(participantKey, section) {
    return (section.items || []).map((timerKey) => {
      const timerConfig = this.config.timers[timerKey]
      if (!timerConfig) return ""

      return `
        <div style="margin-bottom: 12px;">
          <strong>${timerConfig.label}</strong>: <span data-match-state-timer-display="${participantKey}-${timerKey}">${this.formatClock(this.currentAuxiliaryTimerSeconds(participantKey, timerKey))}</span>
          <div class="btn-group btn-group-xs" style="margin-left: 8px;">
            <button type="button" class="btn btn-default" data-match-state-button="timer-action" data-participant-key="${participantKey}" data-timer-key="${timerKey}" data-timer-command="start">Start</button>
            <button type="button" class="btn btn-default" data-match-state-button="timer-action" data-participant-key="${participantKey}" data-timer-key="${timerKey}" data-timer-command="stop">Stop</button>
            <button type="button" class="btn btn-default" data-match-state-button="timer-action" data-participant-key="${participantKey}" data-timer-key="${timerKey}" data-timer-command="reset">Reset</button>
          </div>
          <div class="text-muted" data-match-state-timer-status="${participantKey}-${timerKey}">Max ${this.formatClock(timerConfig.maxSeconds)}</div>
        </div>
      `
    }).join("")
  }

  handleDelegatedClick(event) {
    const button = event.target.closest("button")
    if (!button) return

    // Buttons with direct Stimulus actions are handled separately.
    if (button.dataset.action && button.dataset.action.includes("match-state#")) return

    const buttonType = button.dataset.matchStateButton
    if (buttonType === "score-action") {
      this.applyAction(button)
    } else if (buttonType === "choice-action") {
      this.applyChoice(button)
    } else if (buttonType === "timer-action") {
      this.handleTimerCommand(button)
    } else if (buttonType === "swap-phase") {
      this.swapPhase(button)
    } else if (buttonType === "swap-event") {
      this.swapEvent(button)
    } else if (buttonType === "delete-event") {
      this.deleteEvent(button)
    }
  }

  applyAction(button) {
    const participantKey = button.dataset.participantKey
    const actionKey = button.dataset.actionKey
    if (!applyMatchAction(this.config, this.state, this.currentPhase(), this.currentClockSeconds(), participantKey, actionKey)) return

    this.recomputeDerivedState()
    this.render({ rebuildControls: true })
  }

  applyChoice(button) {
    const phase = this.currentPhase()
    if (phase.type !== "choice") return

    const participantKey = button.dataset.participantKey
    const choiceKey = button.dataset.choiceKey

    const result = applyChoiceAction(this.state, phase, this.currentClockSeconds(), participantKey, choiceKey)
    if (!result.applied) return

    if (result.deferred) {
      this.recomputeDerivedState()
      this.render({ rebuildControls: true })
      return
    }

    this.advancePhase()
  }

  swapColors() {
    this.state.assignment.w1 = this.state.assignment.w1 === "green" ? "red" : "green"
    this.state.assignment.w2 = this.state.assignment.w2 === "green" ? "red" : "green"
    this.render({ rebuildControls: true })
  }

  buildEvent(participantKey, actionKey, options = {}) {
    return buildEventFromEngine(this.state, this.currentPhase(), this.currentClockSeconds(), participantKey, actionKey, options)
  }

  startClock() {
    if (this.currentPhase().type !== "period") return
    const activeClock = this.activeClock()
    if (!startClockState(activeClock)) return
    this.syncClockFromActivePhase()
    this.startTicking()
    this.render()
  }

  stopClock() {
    const activeClock = this.activeClock()
    if (!stopClockState(activeClock)) return
    this.syncClockFromActivePhase()
    this.stopTicking()
    this.render()
  }

  resetClock() {
    this.stopClock()
    const activeClock = this.activeClock()
    if (!activeClock) return
    activeClock.remainingSeconds = activeClock.durationSeconds
    this.syncClockFromActivePhase()
    this.render()
  }

  addMinute() {
    this.adjustClock(60)
  }

  subtractMinute() {
    this.adjustClock(-60)
  }

  addSecond() {
    this.adjustClock(1)
  }

  subtractSecond() {
    this.adjustClock(-1)
  }

  previousPhase() {
    this.stopClock()
    if (!moveToPreviousPhase(this.config, this.state)) return
    this.applyPhaseDefaults()
    this.recomputeDerivedState()
    this.render({ rebuildControls: true })
  }

  nextPhase() {
    this.advancePhase()
  }

  resetMatch() {
    const confirmed = window.confirm("Are you sure you want to reset the match? This will wipe the score, reset all timers, and wipe all stats")
    if (!confirmed) return

    this.stopTicking()
    this.initializeState()
    this.syncClockFromActivePhase()
    this.clearPersistedState()
    this.render({ rebuildControls: true })
  }

  advancePhase() {
    this.stopClock()
    if (!moveToNextPhase(this.config, this.state)) return
    this.applyPhaseDefaults()
    this.recomputeDerivedState()
    this.render({ rebuildControls: true })
  }

  deleteEvent(button) {
    const eventId = Number(button.dataset.eventId)
    if (!deleteEventFromState(this.config, this.state, eventId)) return
    this.recomputeDerivedState()
    this.render({ rebuildControls: true })
  }

  swapEvent(button) {
    const eventId = Number(button.dataset.eventId)
    if (!swapEventParticipants(this.config, this.state, eventId)) return
    this.recomputeDerivedState()
    this.render({ rebuildControls: true })
  }

  swapPhase(button) {
    const phaseKey = button.dataset.phaseKey
    if (!swapPhaseParticipants(this.config, this.state, phaseKey)) return
    this.recomputeDerivedState()
    this.render({ rebuildControls: true })
  }

  handleTimerCommand(button) {
    const participantKey = button.dataset.participantKey
    const timerKey = button.dataset.timerKey
    const command = button.dataset.timerCommand

    if (command === "start") this.startAuxiliaryTimer(participantKey, timerKey)
    if (command === "stop") this.stopAuxiliaryTimer(participantKey, timerKey)
    if (command === "reset") this.resetAuxiliaryTimer(participantKey, timerKey)
  }

  startAuxiliaryTimer(participantKey, timerKey) {
    const timer = this.state.timers[participantKey][timerKey]
    if (!startAuxiliaryTimerState(timer)) return
    this.startTicking()
    this.render()
  }

  stopAuxiliaryTimer(participantKey, timerKey) {
    const timer = this.state.timers[participantKey][timerKey]
    const { stopped, elapsedSeconds } = stopAuxiliaryTimerState(timer)
    if (!stopped) return

    if (elapsedSeconds > 0) {
      this.state.events.push({
        ...this.buildEvent(participantKey, `timer_used_${timerKey}`),
        elapsedSeconds: elapsedSeconds
      })
    }

    this.render()
  }

  resetAuxiliaryTimer(participantKey, timerKey) {
    this.stopAuxiliaryTimer(participantKey, timerKey)
    const timer = this.state.timers[participantKey][timerKey]
    timer.remainingSeconds = this.config.timers[timerKey].maxSeconds
    this.render()
  }

  buildTimerState() {
    return buildTimerState(this.config)
  }

  buildClockState() {
    return buildClockState(this.config)
  }

  currentClockSeconds() {
    return currentClockSecondsFromEngine(this.activeClock())
  }

  currentAuxiliaryTimerSeconds(participantKey, timerKey) {
    return currentAuxiliaryTimerSecondsFromEngine(this.state.timers[participantKey][timerKey])
  }

  hasRunningClockOrTimer() {
    return hasRunningClockOrTimerFromEngine(this.state)
  }

  startTicking() {
    if (this.tickInterval) return
    this.tickInterval = window.setInterval(() => {
      if (this.activeClock()?.running && this.currentClockSeconds() === 0) {
        this.stopClock()
        return
      }

      for (const participantKey of ["w1", "w2"]) {
        for (const timerKey of Object.keys(this.state.timers[participantKey])) {
          if (this.state.timers[participantKey][timerKey].running && this.currentAuxiliaryTimerSeconds(participantKey, timerKey) === 0) {
            this.stopAuxiliaryTimer(participantKey, timerKey)
          }
        }
      }

      this.updateLiveDisplays()
      this.updateTimerDisplays()
    }, 250)
  }

  stopTicking() {
    if (!this.tickInterval) return
    window.clearInterval(this.tickInterval)
    this.tickInterval = null
  }

  stopAllAuxiliaryTimers() {
    stopAllAuxiliaryTimersFromEngine(this.state)
  }

  positionForParticipant(participantKey) {
    if (this.state.displayControl === "neutral") return "neutral"
    if (this.state.displayControl === `${participantKey}_control`) return "top"
    return "bottom"
  }

  opponentParticipant(participantKey) {
    return opponentParticipantFromEngine(participantKey)
  }

  humanizePosition(position) {
    if (position === "neutral") return "Neutral"
    if (position === "green_control") return "Green In Control"
    if (position === "red_control") return "Red In Control"
    return position
  }

  recomputeDerivedState() {
    recomputeDerivedStateFromEngine(this.config, this.state)
  }

  renderEventLog() {
    if (this.state.events.length === 0) {
      return '<p class="text-muted">No events yet.</p>'
    }

    return eventLogSections(this.config, this.state, (seconds) => this.formatClock(seconds)).map((section) => {
      const items = section.items.map((eventRecord) => {
        return `
          <div class="well well-sm" style="margin-bottom: 8px;">
            <div style="display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 8px;">
              <div style="flex: 1 1 260px; min-width: 0; overflow-wrap: anywhere;">
                <strong>${eventRecord.colorLabel}</strong> ${eventRecord.actionLabel}
                <span class="text-muted">(${eventRecord.clockLabel})</span>
              </div>
              <div style="display: flex; flex-wrap: wrap; gap: 8px; flex: 0 0 auto;">
                <button type="button" class="btn btn-xs btn-link" data-match-state-button="swap-event" data-event-id="${eventRecord.id}">Swap</button>
                <button type="button" class="btn btn-xs btn-link" data-match-state-button="delete-event" data-event-id="${eventRecord.id}">Delete</button>
              </div>
            </div>
          </div>
        `
      }).join("")

      return `
        <div style="margin-bottom: 16px;">
          <div style="display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 8px;">
            <h5 style="margin: 0;">${section.label}</h5>
            <button type="button" class="btn btn-xs btn-link" data-match-state-button="swap-phase" data-phase-key="${section.key}">Swap Entire Period</button>
          </div>
          ${items}
        </div>
      `
    }).join("")
  }

  updateLiveDisplays() {
    if (this.hasClockTarget) {
      this.clockTarget.textContent = this.currentPhase().type === "period" ? this.formatClock(this.currentClockSeconds()) : "-"
    }
    if (this.hasClockStatusTarget) {
      this.clockStatusTarget.textContent = this.currentPhase().type === "period"
        ? (this.activeClock()?.running ? "Running" : "Stopped")
        : "Choice"
    }
    if (this.hasAccumulationClockTarget) {
      this.accumulationClockTarget.textContent = this.formatClock(this.accumulatedMatchSeconds())
    }
  }

  updateTimerDisplays() {
    for (const participantKey of ["w1", "w2"]) {
      for (const [timerKey, timerConfig] of Object.entries(this.config.timers)) {
        const display = this.element.querySelector(`[data-match-state-timer-display="${participantKey}-${timerKey}"]`)
        const status = this.element.querySelector(`[data-match-state-timer-status="${participantKey}-${timerKey}"]`)
        if (display) {
          display.textContent = this.formatClock(this.currentAuxiliaryTimerSeconds(participantKey, timerKey))
        }
        if (status) {
          const running = this.state.timers[participantKey][timerKey].running
          status.textContent = `Max ${this.formatClock(timerConfig.maxSeconds)}${running ? " • running" : ""}`
        }
      }
    }
  }

  renderChoiceActions() {
    const phase = this.currentPhase()
    const viewModel = choiceViewModel(this.config, this.state, phase, {
      w1: { name: this.w1NameValue },
      w2: { name: this.w2NameValue }
    })
    if (!viewModel) return ""

    return `
      <div class="well well-sm">
        <div><strong>${viewModel.label}</strong></div>
        <div class="text-muted" style="margin: 6px 0;">${viewModel.selectionText}</div>
        <div>${viewModel.buttons.map((button) => `
          <button
            type="button"
            class="btn ${button.buttonClass} btn-sm"
            data-match-state-button="choice-action"
            data-participant-key="${button.participantKey}"
            data-choice-key="${button.choiceKey}">
            ${button.text}
          </button>
        `).join(" ")}</div>
      </div>
    `
  }

  currentPhase() {
    return this.config.phaseSequence[this.state.phaseIndex]
  }

  applyPhaseDefaults() {
    this.syncClockFromActivePhase()
    this.state.control = this.baseControlForCurrentPhase()
  }

  baseControlForCurrentPhase() {
    return baseControlForPhase(this.currentPhase(), this.state.selections, this.state.control)
  }

  controlFromChoice(selection) {
    return controlFromChoice(selection)
  }

  colorForParticipant(participantKey) {
    return this.state.assignment[participantKey]
  }

  displayLabelForParticipant(participantKey) {
    return this.colorForParticipant(participantKey) === "green" ? "Green" : "Red"
  }

  applyPanelColor(panelElement, color) {
    panelElement.classList.remove("panel-success", "panel-danger")
    panelElement.classList.add(color === "green" ? "panel-success" : "panel-danger")
  }

  controlForSelectedPhase() {
    return controlForSelectedPhase(this.config, this.state)
  }

  baseControlForPhase(phase) {
    return baseControlForPhase(phase, this.state.selections, this.state.control)
  }

  orderedEvents() {
    return orderedEventsFromEngine(this.config, this.state.events)
  }

  phaseIndexForKey(phaseKey) {
    return phaseIndexForKeyFromEngine(this.config, phaseKey)
  }

  activeClock() {
    return activeClockForPhase(this.state, this.currentPhase())
  }

  setupSubscription() {
    this.cleanupSubscription()
    if (!this.matchIdValue || !window.App || !window.App.cable) return

    this.matchSubscription = App.cable.subscriptions.create(
      {
        channel: "MatchChannel",
        match_id: this.matchIdValue
      },
      {
        connected: () => {
          this.isConnected = true
          this.pushDerivedStatsToChannel()
          this.pushScoreboardStateToChannel()
        },
        disconnected: () => {
          this.isConnected = false
        }
      }
    )
  }

  cleanupSubscription() {
    if (!this.matchSubscription) return
    try {
      this.matchSubscription.unsubscribe()
    } catch (_error) {
    }
    this.matchSubscription = null
    this.isConnected = false
  }

  updateStatFieldsAndBroadcast() {
    const derivedStats = this.derivedStats()

    if (this.hasW1StatFieldTarget) this.w1StatFieldTarget.value = derivedStats.w1
    if (this.hasW2StatFieldTarget) this.w2StatFieldTarget.value = derivedStats.w2

    this.lastDerivedStats = derivedStats
    this.pushDerivedStatsToChannel()
    this.pushScoreboardStateToChannel()
  }

  pushDerivedStatsToChannel() {
    if (!this.matchSubscription || !this.lastDerivedStats) return
    this.lastBroadcastStats = performIfChanged(this.matchSubscription, "send_stat", {
      new_w1_stat: this.lastDerivedStats.w1,
      new_w2_stat: this.lastDerivedStats.w2
    }, this.lastBroadcastStats)
  }

  pushScoreboardStateToChannel() {
    if (!this.matchSubscription) return

    this.lastBroadcastScoreboardState = performIfChanged(this.matchSubscription, "send_scoreboard", {
      scoreboard_state: this.scoreboardStatePayload()
    }, this.lastBroadcastScoreboardState)
  }

  applyMatchResultDefaults() {
    const controllerElement = this.matchResultsPanelTarget?.querySelector('[data-controller~="match-score"]')
    if (!controllerElement) return

    const scoreController = this.application.getControllerForElementAndIdentifier(controllerElement, "match-score")
    if (!scoreController || typeof scoreController.applyDefaultResults !== "function") return

    scoreController.applyDefaultResults(
      matchResultDefaultsFromEngine(this.state, {
        w1Id: this.w1IdValue,
        w2Id: this.w2IdValue,
        currentPhase: this.currentPhase(),
        accumulationSeconds: this.accumulatedMatchSeconds()
      })
    )
  }

  scheduleApplyMatchResultDefaults() {
    if (!this.hasMatchResultsPanelTarget) return

    window.clearTimeout(this.matchResultsDefaultsTimeout)
    this.matchResultsDefaultsTimeout = window.setTimeout(() => {
      this.applyMatchResultDefaults()
    }, 0)
  }

  storageKey() {
    return buildStorageKey(this.tournamentIdValue, this.boutNumberValue)
  }

  loadPersistedState() {
    const parsedState = loadJson(window.localStorage, this.storageKey())
    if (!parsedState) {
      if (window.localStorage.getItem(this.storageKey())) {
        this.clearPersistedState()
        this.state = this.buildInitialState()
      }
      return
    }

    try {
      this.state = restorePersistedState(this.config, parsedState)
    } catch (_error) {
      this.clearPersistedState()
      this.state = this.buildInitialState()
    }
  }

  saveState() {
    const persistedState = buildPersistedState(this.state, this.matchMetadata())
    saveJson(window.localStorage, this.storageKey(), persistedState, { ttlMs: MATCH_DATA_TTL_MS })
  }

  clearPersistedState() {
    removeKey(window.localStorage, this.storageKey())
  }

  accumulatedMatchSeconds() {
    return accumulatedMatchSecondsFromEngine(this.config, this.state, this.currentPhase().key)
  }

  syncClockFromActivePhase() {
    this.state.clock = syncClockSnapshot(this.activeClock())
  }

  adjustClock(deltaSeconds) {
    if (this.currentPhase().type !== "period") return

    const activeClock = this.activeClock()
    if (!adjustClockState(activeClock, deltaSeconds)) return
    this.syncClockFromActivePhase()
    this.render()
  }

  formatClock(totalSeconds) {
    const minutes = Math.floor(totalSeconds / 60)
    const seconds = totalSeconds % 60
    return `${minutes}:${seconds.toString().padStart(2, "0")}`
  }

  derivedStats() {
    return derivedStatsFromEngine(this.config, this.state.events)
  }

  scoreboardStatePayload() {
    return scoreboardStatePayloadFromEngine(this.config, this.state, this.matchMetadata())
  }

  matchMetadata() {
    return buildMatchMetadata({
      tournamentId: this.tournamentIdValue,
      boutNumber: this.boutNumberValue,
      weightLabel: this.weightLabelValue,
      ruleset: this.rulesetValue,
      bracketPosition: this.bracketPositionValue,
      w1Name: this.w1NameValue,
      w2Name: this.w2NameValue,
      w1School: this.w1SchoolValue,
      w2School: this.w2SchoolValue
    })
  }
}
