import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "toggle"]

  toggle(event) {
    event.preventDefault()
    const expanded = this.panelTarget.classList.toggle("wd-collapse--open")
    this.toggleTarget.setAttribute("aria-expanded", expanded)
  }
}
