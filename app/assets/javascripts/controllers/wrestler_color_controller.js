import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "w1Takedown", "w1Escape", "w1Reversal", "w1Nf2", "w1Nf3", "w1Nf4", "w1Nf5", "w1Penalty", "w1Penalty2",
    "w1Top", "w1Bottom", "w1Neutral", "w1Defer", "w1Stalling", "w1Caution", "w1ColorSelect",
    "w2Takedown", "w2Escape", "w2Reversal", "w2Nf2", "w2Nf3", "w2Nf4", "w2Nf5", "w2Penalty", "w2Penalty2",
    "w2Top", "w2Bottom", "w2Neutral", "w2Defer", "w2Stalling", "w2Caution", "w2ColorSelect"
  ]

  connect() {
    console.log("Wrestler color controller connected")
    this.initializeColors()
  }

  initializeColors() {
    // Set initial colors based on select values
    this.changeW1Color({ preventRecursion: true })
  }

  changeW1Color(options = {}) {
    const color = this.w1ColorSelectTarget.value
    this.setElementsColor("w1", color)
    
    // Update w2 color to the opposite color unless we're already in a recursive call
    if (!options.preventRecursion) {
      const oppositeColor = color === "green" ? "red" : "green"
      this.w2ColorSelectTarget.value = oppositeColor
      this.setElementsColor("w2", oppositeColor)
    }
  }

  changeW2Color(options = {}) {
    const color = this.w2ColorSelectTarget.value
    this.setElementsColor("w2", color)
    
    // Update w1 color to the opposite color unless we're already in a recursive call
    if (!options.preventRecursion) {
      const oppositeColor = color === "green" ? "red" : "green"
      this.w1ColorSelectTarget.value = oppositeColor
      this.setElementsColor("w1", oppositeColor)
    }
  }

  setElementsColor(wrestler, color) {
    // Define which targets to update for each wrestler
    const targetSuffixes = [
      "Takedown", "Escape", "Reversal", "Nf2", "Nf3", "Nf4", "Nf5", "Penalty", "Penalty2",
      "Top", "Bottom", "Neutral", "Defer", "Stalling", "Caution"
    ]
    
    // For each target type, update the class
    targetSuffixes.forEach(suffix => {
      const targetName = `${wrestler}${suffix}Target`
      if (this[targetName]) {
        // Remove existing color classes
        this[targetName].classList.remove("btn-success", "btn-danger")
        
        // Add new color class
        if (color === "green") {
          this[targetName].classList.add("btn-success")
        } else if (color === "red") {
          this[targetName].classList.add("btn-danger")
        }
      }
    })
  }
} 