import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["stream", "statusIndicator"]

  connect() {
    this.setupSubscription()
  }

  disconnect() {
    this.cleanupSubscription()
  }

  setupSubscription() {
    this.cleanupSubscription()
    this.setStatus("Connecting to server for real-time bout board updates...", "info")

    if (!this.hasStreamTarget) {
      this.setStatus("Error: Stream source not found.", "danger")
      return
    }

    const signedStreamName = this.streamTarget.getAttribute("signed-stream-name")
    if (!signedStreamName) {
      this.setStatus("Error: Invalid stream source.", "danger")
      return
    }

    if (!window.App || !window.App.cable) {
      this.setStatus("Error: WebSockets unavailable. Bout board won't update in real-time. Refresh the page to update.", "danger")
      return
    }

    this.subscription = App.cable.subscriptions.create(
      {
        channel: "Turbo::StreamsChannel",
        signed_stream_name: signedStreamName
      },
      {
        connected: () => {
          this.setStatus("Connected: Bout board updating in real-time.", "success")
        },
        disconnected: () => {
          this.setStatus("Disconnected: Live bout board updates paused.", "warning")
        },
        rejected: () => {
          this.setStatus("Error: Live bout board connection rejected.", "danger")
        }
      }
    )
  }

  cleanupSubscription() {
    if (!this.subscription) return
    this.subscription.unsubscribe()
    this.subscription = null
  }

  setStatus(message, type) {
    if (!this.hasStatusIndicatorTarget) return

    this.statusIndicatorTarget.innerText = message
    this.statusIndicatorTarget.classList.remove("alert-secondary", "alert-info", "alert-success", "alert-warning", "alert-danger")

    if (type === "success") this.statusIndicatorTarget.classList.add("alert-success")
    else if (type === "warning") this.statusIndicatorTarget.classList.add("alert-warning")
    else if (type === "danger") this.statusIndicatorTarget.classList.add("alert-danger")
    else this.statusIndicatorTarget.classList.add("alert-info")
  }
}
