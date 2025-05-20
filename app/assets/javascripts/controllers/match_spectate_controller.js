import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "w1Stats", "w2Stats", "winner", "winType", 
    "score", "finished", "statusIndicator"
  ]

  static values = {
    matchId: Number
  }

  connect() {
    console.log("Match spectate controller connected")
    
    // Setup ActionCable connection if match ID is available
    if (this.matchIdValue) {
      this.setupSubscription(this.matchIdValue)
    } else {
      console.warn("No match ID provided for spectate controller")
    }
  }

  disconnect() {
    this.cleanupSubscription()
  }

  // Clean up the existing subscription
  cleanupSubscription() {
    if (this.matchSubscription) {
      console.log('[Spectator AC Cleanup] Unsubscribing...')
      this.matchSubscription.unsubscribe()
      this.matchSubscription = null
    }
  }

  // Set up the Action Cable subscription for a given matchId
  setupSubscription(matchId) {
    this.cleanupSubscription() // Ensure clean state
    console.log(`[Spectator AC Setup] Attempting subscription for match ID: ${matchId}`)
    
    if (typeof App === 'undefined' || typeof App.cable === 'undefined') {
      console.error("[Spectator AC Setup] Action Cable consumer not found.")
      if (this.hasStatusIndicatorTarget) { 
        this.statusIndicatorTarget.textContent = "Error: AC Not Loaded"
        this.statusIndicatorTarget.classList.remove('text-dark', 'text-success')
        this.statusIndicatorTarget.classList.add('alert-danger', 'text-danger')
      }
      return
    }
    
    // Set initial connecting state for indicator
    if (this.hasStatusIndicatorTarget) { 
      this.statusIndicatorTarget.textContent = "Connecting to backend for live updates..." 
      this.statusIndicatorTarget.classList.remove('alert-danger', 'alert-success', 'text-danger', 'text-success')
      this.statusIndicatorTarget.classList.add('alert-secondary', 'text-dark')
    }

    // Assign to the instance property
    this.matchSubscription = App.cable.subscriptions.create(
      { channel: "MatchChannel", match_id: matchId },
      {
        initialized: () => { 
          console.log(`[Spectator AC Callback] Initialized: ${matchId}`)
          // Set connecting state again in case of retry
          if (this.hasStatusIndicatorTarget) { 
            this.statusIndicatorTarget.textContent = "Connecting to backend for live updates..."
            this.statusIndicatorTarget.classList.remove('alert-danger', 'alert-success', 'text-danger', 'text-success')
            this.statusIndicatorTarget.classList.add('alert-secondary', 'text-dark')
          }
        },
        connected: () => { 
          console.log(`[Spectator AC Callback] CONNECTED: ${matchId}`)
          if (this.hasStatusIndicatorTarget) { 
            this.statusIndicatorTarget.textContent = "Connected to backend for live updates..."
            this.statusIndicatorTarget.classList.remove('alert-danger', 'alert-secondary', 'text-danger', 'text-dark')
            this.statusIndicatorTarget.classList.add('alert-success')
          }
        },
        disconnected: () => { 
          console.log(`[Spectator AC Callback] Disconnected: ${matchId}`)
          if (this.hasStatusIndicatorTarget) { 
            this.statusIndicatorTarget.textContent = "Disconnected from backend for live updates. Retrying..."
            this.statusIndicatorTarget.classList.remove('alert-success', 'alert-secondary', 'text-success', 'text-dark')
            this.statusIndicatorTarget.classList.add('alert-danger')
          }
        },
        rejected: () => { 
          console.error(`[Spectator AC Callback] REJECTED: ${matchId}`)
          if (this.hasStatusIndicatorTarget) { 
            this.statusIndicatorTarget.textContent = "Connection to backend rejected"
            this.statusIndicatorTarget.classList.remove('alert-success', 'alert-secondary', 'text-success', 'text-dark')
            this.statusIndicatorTarget.classList.add('alert-danger')
          }
          this.matchSubscription = null
        },
        received: (data) => {
          console.log("[Spectator AC Callback] Received:", data)
          this.updateDisplayElements(data)
        }
      }
    )
  }

  // Update UI elements with received data
  updateDisplayElements(data) {
    // Update display elements if they exist and data is provided
    if (data.w1_stat !== undefined && this.hasW1StatsTarget) {
      this.w1StatsTarget.textContent = data.w1_stat
    }
    
    if (data.w2_stat !== undefined && this.hasW2StatsTarget) {
      this.w2StatsTarget.textContent = data.w2_stat
    }
    
    if (data.score !== undefined && this.hasScoreTarget) {
      this.scoreTarget.textContent = data.score || '-'
    }
    
    if (data.win_type !== undefined && this.hasWinTypeTarget) {
      this.winTypeTarget.textContent = data.win_type || '-'
    }
    
    if (data.winner_name !== undefined && this.hasWinnerTarget) { 
      this.winnerTarget.textContent = data.winner_name || (data.winner_id ? `ID: ${data.winner_id}` : '-')
    } else if (data.winner_id !== undefined && this.hasWinnerTarget) {
      this.winnerTarget.textContent = data.winner_id ? `ID: ${data.winner_id}` : '-'
    }
    
    if (data.finished !== undefined && this.hasFinishedTarget) {
      this.finishedTarget.textContent = data.finished ? 'Yes' : 'No'
    }
  }
} 