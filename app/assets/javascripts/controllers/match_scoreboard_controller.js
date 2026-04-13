import { Controller } from "@hotwired/stimulus"
import { getMatchStateConfig } from "match-state-config"
import { loadJson } from "match-state-transport"
import {
  buildScoreboardContext,
  connectionPlan,
  applyMatchPayloadContext,
  applyMatPayloadContext,
  applyStatePayloadContext,
  matchStorageKey,
  selectedBoutNumber,
  selectedBoutStorageKey as selectedBoutStorageKeyFromState,
  storageChangePlan
} from "match-state-scoreboard-state"
import {
  boardColors,
  emptyBoardViewModel,
  mainClockRunning as mainClockRunningFromPresenters,
  nextTimerBannerState,
  populatedBoardViewModel,
  timerBannerRenderState
} from "match-state-scoreboard-presenters"

export default class extends Controller {
  static targets = [
    "redSection",
    "centerSection",
    "greenSection",
    "emptyState",
    "redName",
    "redSchool",
    "redScore",
    "redTimerIndicator",
    "greenName",
    "greenSchool",
    "greenScore",
    "greenTimerIndicator",
    "clock",
    "periodLabel",
    "weightLabel",
    "boutLabel",
    "timerBanner",
    "timerBannerLabel",
    "timerBannerClock",
    "redStats",
    "greenStats",
    "lastMatchResult"
  ]

  static values = {
    sourceMode: { type: String, default: "localstorage" },
    displayMode: { type: String, default: "fullscreen" },
    matchId: Number,
    matId: Number,
    tournamentId: Number,
    initialBoutNumber: Number
  }

  connect() {
    this.applyControllerContext(buildScoreboardContext({
      initialBoutNumber: this.initialBoutNumberValue,
      matchId: this.matchIdValue
    }))

    const plan = connectionPlan(this.sourceModeValue, this.currentMatchId)
    if (plan.useStorageListener) {
      this.storageListener = this.handleStorageChange.bind(this)
      window.addEventListener("storage", this.storageListener)
    }
    if (plan.loadSelectedBout) {
      this.loadSelectedBoutNumber()
    }
    if (plan.subscribeMat) {
      this.setupMatSubscription()
    }
    if (plan.loadLocalState) {
      this.loadStateFromLocalStorage()
    }
    if (plan.subscribeMatch) {
      this.setupMatchSubscription(plan.matchId)
    }

    this.startTicking()
    this.render()
  }

  disconnect() {
    if (this.storageListener) {
      window.removeEventListener("storage", this.storageListener)
      this.storageListener = null
    }
    this.unsubscribeMatSubscription()
    this.unsubscribeMatchSubscription()
    if (this.tickInterval) {
      window.clearInterval(this.tickInterval)
      this.tickInterval = null
    }
  }

  setupMatSubscription() {
    if (!window.App || !window.App.cable || !this.matIdValue) return
    if (this.matSubscription) return

    this.matSubscription = App.cable.subscriptions.create(
      {
        channel: "MatScoreboardChannel",
        mat_id: this.matIdValue
      },
      {
        received: (data) => this.handleMatPayload(data)
      }
    )
  }

  unsubscribeMatSubscription() {
    if (this.matSubscription) {
      this.matSubscription.unsubscribe()
      this.matSubscription = null
    }
  }

  setupMatchSubscription(matchId) {
    this.unsubscribeMatchSubscription()
    if (!window.App || !window.App.cable || !matchId) return

    this.matchSubscription = App.cable.subscriptions.create(
      {
        channel: "MatchChannel",
        match_id: matchId
      },
      {
        connected: () => {
          this.matchSubscription.perform("request_sync")
        },
        received: (data) => {
          this.handleMatchPayload(data)
          this.render()
        }
      }
    )
  }

  unsubscribeMatchSubscription() {
    if (this.matchSubscription) {
      this.matchSubscription.unsubscribe()
      this.matchSubscription = null
    }
  }

  handleMatPayload(data) {
    const nextContext = applyMatPayloadContext(this.currentContext(), data)
    this.applyControllerContext(nextContext)

    if (nextContext.loadSelectedBout) {
      this.loadSelectedBoutNumber()
    }
    if (nextContext.loadLocalState) {
      this.loadStateFromLocalStorage()
    }
    if (nextContext.resetTimerBanner) {
      this.resetTimerBannerState()
    }
    if (nextContext.unsubscribeMatch) {
      this.unsubscribeMatchSubscription()
    }
    if (nextContext.subscribeMatchId) {
      this.setupMatchSubscription(nextContext.subscribeMatchId)
    }
    if (nextContext.renderNow) {
      this.render()
    }
  }

  handleMatchPayload(data) {
    this.applyControllerContext(applyMatchPayloadContext(this.currentContext(), data))
  }

  storageKey() {
    return matchStorageKey(this.tournamentIdValue, this.currentBoutNumber)
  }

  selectedBoutStorageKey() {
    return selectedBoutStorageKeyFromState(this.tournamentIdValue, this.matIdValue)
  }

  handleStorageChange(event) {
    const plan = storageChangePlan(this.currentContext(), event.key, this.tournamentIdValue, this.matIdValue)
    if (plan.loadSelectedBout) this.loadSelectedBoutNumber()
    if (plan.loadLocalState) this.loadStateFromLocalStorage()
    if (plan.renderNow) this.render()
  }

  loadSelectedBoutNumber() {
    const parsedSelection = loadJson(window.localStorage, this.selectedBoutStorageKey())
    this.currentBoutNumber = selectedBoutNumber(parsedSelection, this.currentQueueBoutNumber)
  }

  loadStateFromLocalStorage() {
    const storageKey = this.storageKey()
    if (!storageKey) {
      this.state = null
      this.resetTimerBannerState()
      return
    }

    const parsed = loadJson(window.localStorage, storageKey)
    this.applyStatePayload(parsed)
  }

  applyStatePayload(payload) {
    this.applyControllerContext(applyStatePayloadContext(this.currentContext(), payload))
    this.updateTimerBannerState()
  }

  applyControllerContext(context) {
    this.currentQueueBoutNumber = context.currentQueueBoutNumber
    this.currentBoutNumber = context.currentBoutNumber
    this.currentMatchId = context.currentMatchId
    this.liveMatchData = context.liveMatchData
    this.lastMatchResult = context.lastMatchResult
    this.state = context.state
    this.finished = context.finished
    this.timerBannerState = context.timerBannerState || null
    this.previousTimerSnapshot = context.previousTimerSnapshot || {}
  }

  currentContext() {
    return {
      sourceMode: this.sourceModeValue,
      currentQueueBoutNumber: this.currentQueueBoutNumber,
      currentBoutNumber: this.currentBoutNumber,
      currentMatchId: this.currentMatchId,
      liveMatchData: this.liveMatchData,
      lastMatchResult: this.lastMatchResult,
      state: this.state,
      finished: this.finished,
      timerBannerState: this.timerBannerState,
      previousTimerSnapshot: this.previousTimerSnapshot || {}
    }
  }

  startTicking() {
    if (this.tickInterval) return
    this.tickInterval = window.setInterval(() => this.render(), 250)
  }

  render() {
    if (!this.state || !this.state.metadata) {
      this.renderEmptyState()
      return
    }

    this.config = getMatchStateConfig(this.state.metadata.ruleset, this.state.metadata.bracketPosition)
    const viewModel = populatedBoardViewModel(
      this.config,
      this.state,
      this.liveMatchData,
      this.currentBoutNumber,
      (seconds) => this.formatClock(seconds)
    )

    this.applyLiveBoardColors()
    if (this.hasEmptyStateTarget) this.emptyStateTarget.style.display = "none"
    this.applyBoardViewModel(viewModel)
    this.renderTimerBanner()
    this.renderLastMatchResult()
  }

  renderEmptyState() {
    const viewModel = emptyBoardViewModel(this.currentBoutNumber, this.lastMatchResult)
    this.applyEmptyBoardColors()
    if (this.hasEmptyStateTarget) this.emptyStateTarget.style.display = "block"
    this.applyBoardViewModel(viewModel)
    this.hideTimerBanner()
    this.renderLastMatchResult()
  }

  applyBoardViewModel(viewModel) {
    if (this.hasRedNameTarget) this.redNameTarget.textContent = viewModel.redName
    if (this.hasRedSchoolTarget) this.redSchoolTarget.textContent = viewModel.redSchool
    if (this.hasRedScoreTarget) this.redScoreTarget.textContent = viewModel.redScore
    if (this.hasRedTimerIndicatorTarget) this.redTimerIndicatorTarget.innerHTML = this.renderTimerIndicator(viewModel.redTimerIndicator)
    if (this.hasGreenNameTarget) this.greenNameTarget.textContent = viewModel.greenName
    if (this.hasGreenSchoolTarget) this.greenSchoolTarget.textContent = viewModel.greenSchool
    if (this.hasGreenScoreTarget) this.greenScoreTarget.textContent = viewModel.greenScore
    if (this.hasGreenTimerIndicatorTarget) this.greenTimerIndicatorTarget.innerHTML = this.renderTimerIndicator(viewModel.greenTimerIndicator)
    if (this.hasClockTarget) this.clockTarget.textContent = viewModel.clockText
    if (this.hasPeriodLabelTarget) this.periodLabelTarget.textContent = viewModel.phaseLabel
    if (this.hasWeightLabelTarget) this.weightLabelTarget.textContent = viewModel.weightLabel
    if (this.hasBoutLabelTarget) this.boutLabelTarget.textContent = viewModel.boutLabel
    if (this.hasRedStatsTarget) this.redStatsTarget.textContent = viewModel.redStats
    if (this.hasGreenStatsTarget) this.greenStatsTarget.textContent = viewModel.greenStats
  }

  renderLastMatchResult() {
    if (this.hasLastMatchResultTarget) this.lastMatchResultTarget.textContent = this.lastMatchResult || "-"
  }

  renderTimerIndicator(label) {
    if (!label) return ""
    return `<span class="label label-default">${label}</span>`
  }

  applyLiveBoardColors() {
    this.applyBoardColors(boardColors(false))
  }

  applyEmptyBoardColors() {
    this.applyBoardColors(boardColors(true))
  }

  applyBoardColors(colors) {
    if (this.hasRedSectionTarget) this.redSectionTarget.style.background = colors.red
    if (this.hasCenterSectionTarget) this.centerSectionTarget.style.background = colors.center
    if (this.hasGreenSectionTarget) this.greenSectionTarget.style.background = colors.green
  }

  updateTimerBannerState() {
    const nextState = nextTimerBannerState(this.state, this.previousTimerSnapshot)
    this.timerBannerState = nextState.timerBannerState
    this.previousTimerSnapshot = nextState.previousTimerSnapshot
  }

  renderTimerBanner() {
    if (!this.hasTimerBannerTarget) return
    const renderState = timerBannerRenderState(
      this.config,
      this.state,
      this.timerBannerState,
      (seconds) => this.formatClock(seconds)
    )
    this.timerBannerState = renderState.timerBannerState

    if (!renderState.visible) {
      this.hideTimerBanner()
      return
    }

    const viewModel = renderState.viewModel
    this.timerBannerTarget.style.display = "block"
    this.timerBannerTarget.style.borderColor = viewModel.color === "green" ? "#1cab2d" : "#c91f1f"
    if (this.hasTimerBannerLabelTarget) this.timerBannerLabelTarget.textContent = viewModel.label
    if (this.hasTimerBannerClockTarget) this.timerBannerClockTarget.textContent = viewModel.clockText
  }

  hideTimerBanner() {
    if (this.hasTimerBannerTarget) this.timerBannerTarget.style.display = "none"
  }

  resetTimerBannerState() {
    this.timerBannerState = null
    this.previousTimerSnapshot = {}
  }

  mainClockRunning() {
    return mainClockRunningFromPresenters(this.config, this.state)
  }

  formatClock(totalSeconds) {
    const minutes = Math.floor(totalSeconds / 60)
    const seconds = totalSeconds % 60
    return `${minutes}:${seconds.toString().padStart(2, "0")}`
  }
}
