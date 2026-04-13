import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "winType", "overtimeSelect", "winnerSelect", "submitButton", "dynamicScoreInput",
    "finalScoreField", "validationAlerts", "pinTimeTip"
  ]

  static values = {
    winnerScore: { type: String, default: "0" },
    loserScore: { type: String, default: "0" },
    pinMinutes: { type: String, default: "0" },
    pinSeconds: { type: String, default: "00" },
    manualOverride: { type: Boolean, default: false },
    finished: { type: Boolean, default: false }
  }

  connect() {
    console.log("Match score controller connected")
    this.boundMarkManualOverride = this.markManualOverride.bind(this)
    this.element.addEventListener("input", this.boundMarkManualOverride)
    this.element.addEventListener("change", this.boundMarkManualOverride)
    if (this.finishedValue) {
      this.validateForm()
      return
    }
    setTimeout(() => {
      this.updateScoreInput()
      this.validateForm()
    }, 50)
  }

  disconnect() {
    this.element.removeEventListener("input", this.boundMarkManualOverride)
    this.element.removeEventListener("change", this.boundMarkManualOverride)
  }

  winTypeChanged() {
    if (this.finishedValue) {
      this.validateForm()
      return
    }
    this.updateScoreInput()
    this.validateForm()
  }

  winnerChanged() {
    this.validateForm()
  }

  updateScoreInput() {
    if (this.finishedValue) return
    const winType = this.winTypeTarget.value
    this.dynamicScoreInputTarget.innerHTML = ""
    
    // Add section header
    const header = document.createElement("h5")
    header.innerText = `Score Input for ${winType}`
    header.classList.add("mt-2", "mb-3")
    this.dynamicScoreInputTarget.appendChild(header)

    if (winType === "Pin") {
      this.pinTimeTipTarget.style.display = "block"
      
      const minuteInput = this.createTextInput("minutes", "Minutes (MM)", "Pin Time Minutes")
      const secondInput = this.createTextInput("seconds", "Seconds (SS)", "Pin Time Seconds")
      
      this.dynamicScoreInputTarget.appendChild(minuteInput)
      this.dynamicScoreInputTarget.appendChild(secondInput)

      minuteInput.querySelector("input").value = this.pinMinutesValue || "0"
      secondInput.querySelector("input").value = this.pinSecondsValue || "00"
      
      // Add event listeners to the new inputs
      const inputs = this.dynamicScoreInputTarget.querySelectorAll("input")
      inputs.forEach(input => {
        input.addEventListener("input", () => {
          this.updatePinTimeScore()
          this.validateForm()
        })
      })
      
      this.updatePinTimeScore()
    } else if (["Decision", "Major", "Tech Fall"].includes(winType)) {
      this.pinTimeTipTarget.style.display = "none"
      
      const winnerScoreInput = this.createTextInput(
        "winner-score",
        "Winner's Score",
        "Enter the winner's score"
      )
      const loserScoreInput = this.createTextInput(
        "loser-score",
        "Loser's Score",
        "Enter the loser's score"
      )
      
      this.dynamicScoreInputTarget.appendChild(winnerScoreInput)
      this.dynamicScoreInputTarget.appendChild(loserScoreInput)
      
      // Restore stored values
      const winnerInput = winnerScoreInput.querySelector("input")
      const loserInput = loserScoreInput.querySelector("input")
      
      winnerInput.value = this.winnerScoreValue
      loserInput.value = this.loserScoreValue
      
      // Add event listeners to the new inputs
      winnerInput.addEventListener("input", (event) => {
        this.winnerScoreValue = event.target.value || "0"
        this.updatePointScore()
        this.validateForm()
      })
      
      loserInput.addEventListener("input", (event) => {
        this.loserScoreValue = event.target.value || "0"
        this.updatePointScore()
        this.validateForm()
      })
      
      this.updatePointScore()
    } else {
      // For other types (forfeit, etc.), clear the input and hide pin time tip
      this.pinTimeTipTarget.style.display = "none"
      this.finalScoreFieldTarget.value = ""
      
      // Show message for non-score win types
      const message = document.createElement("p")
      message.innerText = `No score required for ${winType} win type.`
      message.classList.add("text-muted")
      this.dynamicScoreInputTarget.appendChild(message)
    }
    
    this.validateForm()
  }

  applyDefaultResults(defaults = {}) {
    if (this.manualOverrideValue || this.finishedValue) return

    if (Object.prototype.hasOwnProperty.call(defaults, "winnerId") && this.hasWinnerSelectTarget) {
      this.winnerSelectTarget.value = defaults.winnerId ? String(defaults.winnerId) : ""
    }

    if (Object.prototype.hasOwnProperty.call(defaults, "overtimeType") && this.hasOvertimeSelectTarget) {
      const allowedValues = Array.from(this.overtimeSelectTarget.options).map((option) => option.value)
      this.overtimeSelectTarget.value = allowedValues.includes(defaults.overtimeType) ? defaults.overtimeType : ""
    }

    if (Object.prototype.hasOwnProperty.call(defaults, "winnerScore")) {
      this.winnerScoreValue = String(defaults.winnerScore)
    }

    if (Object.prototype.hasOwnProperty.call(defaults, "loserScore")) {
      this.loserScoreValue = String(defaults.loserScore)
    }

    if (Object.prototype.hasOwnProperty.call(defaults, "pinMinutes")) {
      this.pinMinutesValue = String(defaults.pinMinutes)
    }

    if (Object.prototype.hasOwnProperty.call(defaults, "pinSeconds")) {
      this.pinSecondsValue = String(defaults.pinSeconds).padStart(2, "0")
    }

    this.updateScoreInput()
    this.validateForm()
  }

  markManualOverride(event) {
    if (!event.isTrusted) return
    this.manualOverrideValue = true
  }

  updatePinTimeScore() {
    const minuteInput = this.dynamicScoreInputTarget.querySelector("#minutes")
    const secondInput = this.dynamicScoreInputTarget.querySelector("#seconds")
    
    if (minuteInput && secondInput) {
      const minutes = (minuteInput.value || "0").padStart(2, "0")
      const seconds = (secondInput.value || "0").padStart(2, "0")
      this.finalScoreFieldTarget.value = `${minutes}:${seconds}`
      
      // Validate after updating pin time
      this.validateForm()
    }
  }

  updatePointScore() {
    const winnerScore = this.winnerScoreValue || "0"
    const loserScore = this.loserScoreValue || "0"
    this.finalScoreFieldTarget.value = `${winnerScore}-${loserScore}`
    
    // Validate immediately after updating scores
    this.validateForm()
  }

  validateForm() {
    const winType = this.winTypeTarget.value
    const winner = this.winnerSelectTarget?.value
    let isValid = true
    let alertMessage = ""
    let winTypeShouldBe = "Decision"

    // Clear previous validation messages
    this.validationAlertsTarget.innerHTML = ""
    this.validationAlertsTarget.style.display = "none"
    this.validationAlertsTarget.classList.remove("alert", "alert-danger", "p-3")

    if (["Decision", "Major", "Tech Fall"].includes(winType)) {
      // Get scores and ensure they're valid numbers
      const winnerScore = parseInt(this.winnerScoreValue || "0", 10)
      const loserScore = parseInt(this.loserScoreValue || "0", 10)
      
      console.log(`Validating scores: winner=${winnerScore}, loser=${loserScore}, type=${winType}`)
      
      // Check if winner score > loser score
      if (winnerScore <= loserScore) {
        isValid = false
        alertMessage += "<strong>Error:</strong> Winner's score must be higher than loser's score.<br>"
      } else {
        // Calculate score difference and determine correct win type
        const scoreDifference = winnerScore - loserScore
        
        if (scoreDifference < 8) {
          winTypeShouldBe = "Decision"
        } else if (scoreDifference >= 8 && scoreDifference < 15) {
          winTypeShouldBe = "Major"
        } else if (scoreDifference >= 15) {
          winTypeShouldBe = "Tech Fall"
        }
        
        // Check if selected win type matches the correct one based on score difference
        if (winTypeShouldBe !== winType) {
          isValid = false
          alertMessage += `
            <strong>Win Type Error:</strong> Win type should be <strong>${winTypeShouldBe}</strong>.<br>
            <ul>
              <li>Decisions are wins with a score difference less than 8.</li>
              <li>Majors are wins with a score difference between 8 and 14.</li>
              <li>Tech Falls are wins with a score difference of 15 or more.</li>
            </ul>
          `
        }
      }
    }

    // Check if a winner is selected
    if (!winner) {
      isValid = false
      alertMessage += "<strong>Error:</strong> Please select a winner.<br>"
    }

    // Display validation messages if any
    if (alertMessage) {
      this.validationAlertsTarget.innerHTML = alertMessage
      this.validationAlertsTarget.style.display = "block"
      this.validationAlertsTarget.classList.add("alert", "alert-danger", "p-3")
    }

    // Enable/disable submit button based on validation result
    this.submitButtonTarget.disabled = !isValid
    
    // Return validation result for potential use elsewhere
    return isValid
  }

  createTextInput(id, placeholder, label) {
    const container = document.createElement("div")
    container.classList.add("form-group", "mb-2")

    const inputLabel = document.createElement("label")
    inputLabel.innerText = label
    inputLabel.classList.add("form-label")
    inputLabel.setAttribute("for", id)

    const input = document.createElement("input")
    input.type = "text"
    input.id = id
    input.placeholder = placeholder
    input.classList.add("form-control")
    input.style.width = "100%"
    input.style.maxWidth = "400px"

    container.appendChild(inputLabel)
    container.appendChild(input)
    return container
  }

  confirmWinner(event) {
    const winnerSelect = this.winnerSelectTarget;
    const selectedOption = winnerSelect.options[winnerSelect.selectedIndex];
    
    if (!confirm('Is the name of the winner ' + selectedOption.text + '?')) {
      event.preventDefault();
    }
  }
} 
