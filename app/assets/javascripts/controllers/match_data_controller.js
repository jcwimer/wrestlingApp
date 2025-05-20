import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "w1Stat", "w2Stat", "statusIndicator"
  ]

  static values = {
    tournamentId: Number,
    boutNumber: Number,
    matchId: Number
  }

  connect() {
    console.log("Match data controller connected")
    
    this.w1 = {
      name: "w1",
      stats: "",
      updated_at: null,
      timers: {
        "injury": { time: 0, startTime: null, interval: null },
        "blood": { time: 0, startTime: null, interval: null }
      }
    }
    
    this.w2 = {
      name: "w2",
      stats: "", 
      updated_at: null,
      timers: {
        "injury": { time: 0, startTime: null, interval: null },
        "blood": { time: 0, startTime: null, interval: null }
      }
    }
    
    // Initial values
    this.updateJsValues()
    
    // Set up debounced handlers for text areas
    this.debouncedW1Handler = this.debounce((el) => this.handleTextAreaInput(el, this.w1), 400)
    this.debouncedW2Handler = this.debounce((el) => this.handleTextAreaInput(el, this.w2), 400)
    
    // Set up text area event listeners
    this.w1StatTarget.addEventListener('input', (event) => this.debouncedW1Handler(event.target))
    this.w2StatTarget.addEventListener('input', (event) => this.debouncedW2Handler(event.target))
    
    // Initialize from local storage
    this.initializeFromLocalStorage()
    
    // Setup ActionCable
    if (this.matchIdValue) {
      this.setupSubscription(this.matchIdValue)
    }
  }
  
  disconnect() {
    this.cleanupSubscription()
  }
  
  // Match stats core functionality
  updateStats(wrestler, text) {
    if (!wrestler) { 
      console.error("updateStats called with undefined wrestler")
      return
    }
    
    wrestler.stats += text + " "
    wrestler.updated_at = new Date().toISOString()
    this.updateHtmlValues()
    this.saveToLocalStorage(wrestler)
    
    // Send the update via Action Cable if subscribed
    if (this.matchSubscription) {
      let payload = {}
      if (wrestler.name === 'w1') payload.new_w1_stat = wrestler.stats
      else if (wrestler.name === 'w2') payload.new_w2_stat = wrestler.stats
      
      if (Object.keys(payload).length > 0) {
        console.log('[ActionCable] updateStats performing send_stat:', payload)
        this.matchSubscription.perform('send_stat', payload)
      }
    } else {
      console.warn('[ActionCable] updateStats called but matchSubscription is null.')
    }
  }
  
  // Specific methods for updating each wrestler
  updateW1Stats(event) {
    const text = event.currentTarget.dataset.matchDataText || ''
    this.updateStats(this.w1, text)
  }

  updateW2Stats(event) {
    const text = event.currentTarget.dataset.matchDataText || ''
    this.updateStats(this.w2, text)
  }

  // End period action
  endPeriod() {
    this.updateStats(this.w1, '|End Period|')
    this.updateStats(this.w2, '|End Period|')
  }
  
  handleTextAreaInput(textAreaElement, wrestler) {
    const newValue = textAreaElement.value
    console.log(`Text area input detected for ${wrestler.name}:`, newValue.substring(0, 50) + "...")
    
    // Update the internal JS object
    wrestler.stats = newValue
    wrestler.updated_at = new Date().toISOString()
    
    // Save to localStorage
    this.saveToLocalStorage(wrestler)
    
    // Send the update via Action Cable if subscribed
    if (this.matchSubscription) {
      let payload = {}
      if (wrestler.name === 'w1') {
        payload.new_w1_stat = wrestler.stats
      } else if (wrestler.name === 'w2') {
        payload.new_w2_stat = wrestler.stats
      }
      if (Object.keys(payload).length > 0) {
        console.log('[ActionCable] Performing send_stat from textarea with payload:', payload)
        this.matchSubscription.perform('send_stat', payload)
      }
    }
  }
  
  // Timer functions
  startTimer(wrestler, timerKey) {
    const timer = wrestler.timers[timerKey]
    if (timer.interval) return // Prevent multiple intervals
    
    timer.startTime = Date.now()
    timer.interval = setInterval(() => {
      const elapsedSeconds = Math.floor((Date.now() - timer.startTime) / 1000)
      this.updateTimerDisplay(wrestler, timerKey, timer.time + elapsedSeconds)
    }, 1000)
  }
  
  stopTimer(wrestler, timerKey) {
    const timer = wrestler.timers[timerKey]
    if (!timer.interval || !timer.startTime) return
    
    clearInterval(timer.interval)
    const elapsedSeconds = Math.floor((Date.now() - timer.startTime) / 1000)
    timer.time += elapsedSeconds
    timer.interval = null
    timer.startTime = null
    
    this.saveToLocalStorage(wrestler)
    this.updateTimerDisplay(wrestler, timerKey, timer.time)
    this.updateStatsBox(wrestler, timerKey, elapsedSeconds)
  }
  
  resetTimer(wrestler, timerKey) {
    const timer = wrestler.timers[timerKey]
    this.stopTimer(wrestler, timerKey)
    timer.time = 0
    this.updateTimerDisplay(wrestler, timerKey, 0)
    this.saveToLocalStorage(wrestler)
  }
  
  // Timer control methods for W1
  startW1InjuryTimer() {
    this.startTimer(this.w1, 'injury')
  }

  stopW1InjuryTimer() {
    this.stopTimer(this.w1, 'injury')
  }

  resetW1InjuryTimer() {
    this.resetTimer(this.w1, 'injury')
  }

  startW1BloodTimer() {
    this.startTimer(this.w1, 'blood')
  }

  stopW1BloodTimer() {
    this.stopTimer(this.w1, 'blood')
  }

  resetW1BloodTimer() {
    this.resetTimer(this.w1, 'blood')
  }

  // Timer control methods for W2
  startW2InjuryTimer() {
    this.startTimer(this.w2, 'injury')
  }

  stopW2InjuryTimer() {
    this.stopTimer(this.w2, 'injury')
  }

  resetW2InjuryTimer() {
    this.resetTimer(this.w2, 'injury')
  }

  startW2BloodTimer() {
    this.startTimer(this.w2, 'blood')
  }

  stopW2BloodTimer() {
    this.stopTimer(this.w2, 'blood')
  }

  resetW2BloodTimer() {
    this.resetTimer(this.w2, 'blood')
  }
  
  updateTimerDisplay(wrestler, timerKey, totalTime) {
    const elementId = `${wrestler.name}-${timerKey}-time`
    const element = document.getElementById(elementId)
    if (element) {
      element.innerText = `${Math.floor(totalTime / 60)}m ${totalTime % 60}s`
    }
  }
  
  updateStatsBox(wrestler, timerKey, elapsedSeconds) {
    const timerType = timerKey.includes("injury") ? "Injury Time" : "Blood Time"
    const formattedTime = `${Math.floor(elapsedSeconds / 60)}m ${elapsedSeconds % 60}s`
    this.updateStats(wrestler, `${timerType}: ${formattedTime}`)
  }
  
  // Utility functions
  generateKey(wrestler_name) {
    return `${wrestler_name}-${this.tournamentIdValue}-${this.boutNumberValue}`
  }
  
  loadFromLocalStorage(wrestler_name) {
    const key = this.generateKey(wrestler_name)
    const data = localStorage.getItem(key)
    return data ? JSON.parse(data) : null
  }
  
  saveToLocalStorage(person) {
    const key = this.generateKey(person.name)
    const data = {
      stats: person.stats,
      updated_at: person.updated_at,
      timers: person.timers
    }
    localStorage.setItem(key, JSON.stringify(data))
  }
  
  updateHtmlValues() {
    if (this.w1StatTarget) this.w1StatTarget.value = this.w1.stats
    if (this.w2StatTarget) this.w2StatTarget.value = this.w2.stats
  }
  
  updateJsValues() {
    if (this.w1StatTarget) this.w1.stats = this.w1StatTarget.value
    if (this.w2StatTarget) this.w2.stats = this.w2StatTarget.value
  }
  
  debounce(func, wait) {
    let timeout
    return (...args) => {
      clearTimeout(timeout)
      timeout = setTimeout(() => func(...args), wait)
    }
  }
  
  initializeTimers(wrestler) {
    for (const timerKey in wrestler.timers) {
      this.updateTimerDisplay(wrestler, timerKey, wrestler.timers[timerKey].time)
    }
  }
  
  initializeFromLocalStorage() {
    const w1Data = this.loadFromLocalStorage('w1')
    if (w1Data) {
      this.w1.stats = w1Data.stats || ''
      this.w1.updated_at = w1Data.updated_at
      if (w1Data.timers) this.w1.timers = w1Data.timers
      this.initializeTimers(this.w1)
    }
    
    const w2Data = this.loadFromLocalStorage('w2')
    if (w2Data) {
      this.w2.stats = w2Data.stats || ''
      this.w2.updated_at = w2Data.updated_at
      if (w2Data.timers) this.w2.timers = w2Data.timers
      this.initializeTimers(this.w2)
    }
    
    this.updateHtmlValues()
  }
  
  cleanupSubscription() {
    if (this.matchSubscription) {
      console.log(`[Stats AC Cleanup] Unsubscribing from match channel.`)
      try {
        this.matchSubscription.unsubscribe()
      } catch (e) {
        console.error(`[Stats AC Cleanup] Error during unsubscribe:`, e)
      }
      this.matchSubscription = null
    }
  }
  
  setupSubscription(matchId) {
    this.cleanupSubscription()
    console.log(`[Stats AC Setup] Attempting subscription for match ID: ${matchId}`)
    
    // Update status indicator
    if (this.statusIndicatorTarget) {
      this.statusIndicatorTarget.innerText = "Connecting to server for real-time stat updates..."
      this.statusIndicatorTarget.classList.remove('alert-success', 'alert-warning', 'alert-danger')
      this.statusIndicatorTarget.classList.add('alert-info')
    }
    
    // Exit if we don't have App.cable
    if (!window.App || !window.App.cable) {
      console.error(`[Stats AC Setup] Error: App.cable is not available.`)
      if (this.statusIndicatorTarget) {
        this.statusIndicatorTarget.innerText = "Error: WebSockets unavailable. Stats won't update in real-time."
        this.statusIndicatorTarget.classList.remove('alert-info', 'alert-success', 'alert-warning')
        this.statusIndicatorTarget.classList.add('alert-danger')
      }
      return
    }
    
    this.matchSubscription = App.cable.subscriptions.create(
      {
        channel: "MatchChannel",
        match_id: matchId
      },
      {
        connected: () => {
          console.log(`[Stats AC] Connected to MatchStatsChannel for match ID: ${matchId}`)
          if (this.statusIndicatorTarget) {
            this.statusIndicatorTarget.innerText = "Connected: Stats will update in real-time."
            this.statusIndicatorTarget.classList.remove('alert-info', 'alert-warning', 'alert-danger')
            this.statusIndicatorTarget.classList.add('alert-success')
          }
        },
        
        disconnected: () => {
          console.log(`[Stats AC] Disconnected from MatchStatsChannel`)
          if (this.statusIndicatorTarget) {
            this.statusIndicatorTarget.innerText = "Disconnected: Stats updates paused."
            this.statusIndicatorTarget.classList.remove('alert-info', 'alert-success', 'alert-danger')
            this.statusIndicatorTarget.classList.add('alert-warning')
          }
        },
        
        received: (data) => {
          console.log(`[Stats AC] Received data:`, data)
          
          // Update w1 stats
          if (data.w1_stat !== undefined && this.w1StatTarget) {
            console.log(`[Stats AC] Updating w1_stat: ${data.w1_stat.substring(0, 30)}...`)
            this.w1.stats = data.w1_stat
            this.w1StatTarget.value = data.w1_stat
          }
          
          // Update w2 stats
          if (data.w2_stat !== undefined && this.w2StatTarget) {
            console.log(`[Stats AC] Updating w2_stat: ${data.w2_stat.substring(0, 30)}...`)
            this.w2.stats = data.w2_stat
            this.w2StatTarget.value = data.w2_stat
          }
        },
        
        receive_error: (error) => {
          console.error(`[Stats AC] Error:`, error)
          this.matchSubscription = null
          
          if (this.statusIndicatorTarget) {
            this.statusIndicatorTarget.innerText = "Error: Connection issue. Stats won't update in real-time."
            this.statusIndicatorTarget.classList.remove('alert-info', 'alert-success', 'alert-warning')
            this.statusIndicatorTarget.classList.add('alert-danger')
          }
        }
      }
    )
  }
} 