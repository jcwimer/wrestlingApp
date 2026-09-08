import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  dismiss(event) {
    event.preventDefault()
    this.element.remove()
  }
}
