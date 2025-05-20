import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "winType", "winnerSelect", "submitButton", "dynamicScoreInput", 
    "finalScoreField", "validationAlerts", "pinTimeTip"
  ]

  static values = {
    winnerScore: { type: String, default: "0" },
    loserScore: { type: String, default: "0" }
  }

  connect() {
    console.log("Match score controller connected")
    // Use setTimeout to ensure the DOM is fully loaded
    setTimeout(() => {
      this.updateScoreInput()
      this.validateForm()
    }, 50)
  }

  winTypeChanged() {
    this.updateScoreInput()
    this.validateForm()
  }

  winnerChanged() {
    this.validateForm()
  }

  updateScoreInput() {
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