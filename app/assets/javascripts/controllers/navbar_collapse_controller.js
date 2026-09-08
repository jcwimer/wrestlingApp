import { Controller } from "@hotwired/stimulus"

const DESKTOP_BREAKPOINT = "(min-width: 768px)"

export default class extends Controller {
  static targets = ["panel", "toggle"]

  connect() {
    this.mediaQuery = window.matchMedia(DESKTOP_BREAKPOINT)
    this.onMediaChange = this.handleMediaChange.bind(this)
    this.mediaQuery.addEventListener("change", this.onMediaChange)
    this.handleMediaChange()
  }

  disconnect() {
    this.mediaQuery?.removeEventListener("change", this.onMediaChange)
  }

  toggle() {
    if (this.mediaQuery.matches) return

    const expanded = this.panelTarget.classList.toggle("wd-collapse--open")
    this.toggleTarget.setAttribute("aria-expanded", expanded)
  }

  handleMediaChange() {
    if (this.mediaQuery.matches) {
      this.panelTarget.classList.add("wd-collapse--open")
      this.toggleTarget.setAttribute("aria-expanded", "true")
    } else {
      this.panelTarget.classList.remove("wd-collapse--open")
      this.toggleTarget.setAttribute("aria-expanded", "false")
    }
  }
}
