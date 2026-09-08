import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle"]

  connect() {
    this.boundCloseOnOutsideClick = this.closeOnOutsideClick.bind(this)
    this.boundCloseOnEscape = this.closeOnEscape.bind(this)
  }

  disconnect() {
    this.close()
  }

  toggle(event) {
    event.preventDefault()

    if (this.element.classList.contains("wd-dropdown--open")) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.element.classList.add("wd-dropdown--open")
    this.toggleTarget.setAttribute("aria-expanded", "true")
    document.addEventListener("click", this.boundCloseOnOutsideClick)
    document.addEventListener("keydown", this.boundCloseOnEscape)
  }

  close() {
    this.element.classList.remove("wd-dropdown--open")
    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute("aria-expanded", "false")
    }
    document.removeEventListener("click", this.boundCloseOnOutsideClick)
    document.removeEventListener("keydown", this.boundCloseOnEscape)
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
      this.toggleTarget?.focus()
    }
  }
}
