import { Controller } from "@hotwired/stimulus"
import {
  loadJson,
  removeKey,
  saveJson,
  SHORT_LIVED_TTL_MS
} from "match-state-transport"

export default class extends Controller {
  static values = {
    tournamentId: Number,
    matId: Number,
    boutNumber: Number,
    matchId: Number,
    selectMatchUrl: String,
    weightLabel: String,
    w1Id: Number,
    w2Id: Number,
    w1Name: String,
    w2Name: String,
    w1School: String,
    w2School: String
  }

  connect() {
    this.boundHandleSubmit = this.handleSubmit.bind(this)
    this.saveSelectedBout()
    this.broadcastSelectedBout()
    this.element.addEventListener("submit", this.boundHandleSubmit)
  }

  disconnect() {
    this.element.removeEventListener("submit", this.boundHandleSubmit)
  }

  storageKey() {
    return `mat-selected-bout:${this.tournamentIdValue}:${this.matIdValue}`
  }

  saveSelectedBout() {
    if (!this.matIdValue || this.matIdValue <= 0) return

    try {
      saveJson(window.localStorage, this.storageKey(), {
        boutNumber: this.boutNumberValue,
        matchId: this.matchIdValue,
        updatedAt: Date.now()
      }, { ttlMs: SHORT_LIVED_TTL_MS })
    } catch (_error) {
    }
  }

  broadcastSelectedBout() {
    if (!this.hasSelectMatchUrlValue || !this.selectMatchUrlValue) return

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    const body = new URLSearchParams()
    if (this.matchIdValue) body.set("match_id", this.matchIdValue.toString())
    if (this.boutNumberValue) body.set("bout_number", this.boutNumberValue.toString())

    const lastMatchResult = this.loadLastMatchResult()
    if (lastMatchResult) body.set("last_match_result", lastMatchResult)

    fetch(this.selectMatchUrlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken || "",
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
        "Accept": "text/vnd.turbo-stream.html, text/html, application/xhtml+xml"
      },
      body,
      credentials: "same-origin"
    }).catch(() => {})
  }

  lastMatchResultStorageKey() {
    return `mat-last-match-result:${this.tournamentIdValue}:${this.matIdValue}`
  }

  saveLastMatchResult(text) {
    if (!this.matIdValue || this.matIdValue <= 0) return

    try {
      if (text) {
        saveJson(window.localStorage, this.lastMatchResultStorageKey(), text, { ttlMs: SHORT_LIVED_TTL_MS })
      } else {
        removeKey(window.localStorage, this.lastMatchResultStorageKey())
      }
    } catch (_error) {
    }
  }

  loadLastMatchResult() {
    try {
      return loadJson(window.localStorage, this.lastMatchResultStorageKey()) || ""
    } catch (_error) {
      return ""
    }
  }

  handleSubmit(event) {
    const form = event.target
    if (!(form instanceof HTMLFormElement)) return

    const resultText = this.buildLastMatchResult(form)
    if (!resultText) return

    this.saveLastMatchResult(resultText)
    this.broadcastCurrentState(resultText)
  }

  broadcastCurrentState(lastMatchResult) {
    if (!this.hasSelectMatchUrlValue || !this.selectMatchUrlValue) return

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    const body = new URLSearchParams()
    if (this.matchIdValue) body.set("match_id", this.matchIdValue.toString())
    if (this.boutNumberValue) body.set("bout_number", this.boutNumberValue.toString())
    if (lastMatchResult) body.set("last_match_result", lastMatchResult)

    fetch(this.selectMatchUrlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken || "",
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
        "Accept": "text/vnd.turbo-stream.html, text/html, application/xhtml+xml"
      },
      body,
      credentials: "same-origin",
      keepalive: true
    }).catch(() => {})
  }

  buildLastMatchResult(form) {
    const winnerId = form.querySelector("#match_winner_id")?.value
    const winType = form.querySelector("#match_win_type")?.value
    const score = form.querySelector("#final-score-field")?.value
    if (!winnerId || !winType) return ""

    const winner = this.participantDataForId(winnerId)
    const loser = this.loserParticipantData(winnerId)
    if (!winner || !loser) return ""

    const weightLabel = this.hasWeightLabelValue ? this.weightLabelValue : ""
    return `${weightLabel} lbs - ${winner.name} (${winner.school}) ${winType} ${loser.name} (${loser.school}) ${score || ""}`.trim()
  }

  participantDataForId(participantId) {
    const normalizedId = String(participantId)
    if (normalizedId === String(this.w1IdValue)) {
      return { name: this.w1NameValue, school: this.w1SchoolValue }
    }
    if (normalizedId === String(this.w2IdValue)) {
      return { name: this.w2NameValue, school: this.w2SchoolValue }
    }
    return null
  }

  loserParticipantData(winnerId) {
    const normalizedId = String(winnerId)
    if (normalizedId === String(this.w1IdValue)) {
      return { name: this.w2NameValue, school: this.w2SchoolValue }
    }
    if (normalizedId === String(this.w2IdValue)) {
      return { name: this.w1NameValue, school: this.w1SchoolValue }
    }
    return null
  }
}
