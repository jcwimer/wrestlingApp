import { beforeEach, describe, expect, it, vi } from "vitest"
import MatchSpectateController from "../../../app/assets/javascripts/controllers/match_spectate_controller.js"

function makeTarget() {
  return {
    textContent: "",
    style: {},
    classList: {
      add: vi.fn(),
      remove: vi.fn()
    }
  }
}

function buildController() {
  const controller = new MatchSpectateController()
  controller.matchIdValue = 22
  controller.hasW1StatsTarget = true
  controller.hasW2StatsTarget = true
  controller.hasWinnerTarget = true
  controller.hasWinTypeTarget = true
  controller.hasScoreTarget = true
  controller.hasFinishedTarget = true
  controller.hasStatusIndicatorTarget = true
  controller.hasScoreboardContainerTarget = true
  controller.w1StatsTarget = makeTarget()
  controller.w2StatsTarget = makeTarget()
  controller.winnerTarget = makeTarget()
  controller.winTypeTarget = makeTarget()
  controller.scoreTarget = makeTarget()
  controller.finishedTarget = makeTarget()
  controller.statusIndicatorTarget = makeTarget()
  controller.scoreboardContainerTarget = makeTarget()
  return controller
}

describe("match spectate controller", () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    delete global.App
  })

  it("connect subscribes to the match when a match id is present", () => {
    const controller = buildController()
    controller.setupSubscription = vi.fn()

    controller.connect()

    expect(controller.setupSubscription).toHaveBeenCalledWith(22)
  })

  it("setupSubscription reports ActionCable missing", () => {
    const controller = buildController()

    controller.setupSubscription(22)

    expect(controller.statusIndicatorTarget.textContent).toBe("Error: AC Not Loaded")
    expect(controller.statusIndicatorTarget.classList.add).toHaveBeenCalledWith("alert-danger", "text-danger")
  })

  it("subscription callbacks update status and request initial sync", () => {
    const controller = buildController()
    const subscription = { perform: vi.fn(), unsubscribe: vi.fn() }
    let callbacks
    global.App = {
      cable: {
        subscriptions: {
          create: vi.fn((_identifier, receivedCallbacks) => {
            callbacks = receivedCallbacks
            return subscription
          })
        }
      }
    }

    controller.setupSubscription(22)
    callbacks.initialized()
    expect(controller.statusIndicatorTarget.textContent).toBe("Connecting to backend for live updates...")

    callbacks.connected()
    expect(controller.statusIndicatorTarget.textContent).toBe("Connected to backend for live updates...")
    expect(subscription.perform).toHaveBeenCalledWith("request_sync")

    callbacks.disconnected()
    expect(controller.statusIndicatorTarget.textContent).toBe("Disconnected from backend for live updates. Retrying...")

    callbacks.rejected()
    expect(controller.statusIndicatorTarget.textContent).toBe("Connection to backend rejected")
    expect(controller.matchSubscription).toBe(null)
  })

  it("received websocket payloads update stats and result fields", () => {
    const controller = buildController()

    controller.updateDisplayElements({
      w1_stat: "T3",
      w2_stat: "E1",
      score: "3-1",
      win_type: "Decision",
      winner_name: "Alpha",
      finished: 0
    })

    expect(controller.w1StatsTarget.textContent).toBe("T3")
    expect(controller.w2StatsTarget.textContent).toBe("E1")
    expect(controller.scoreTarget.textContent).toBe("3-1")
    expect(controller.winTypeTarget.textContent).toBe("Decision")
    expect(controller.winnerTarget.textContent).toBe("Alpha")
    expect(controller.finishedTarget.textContent).toBe("No")
    expect(controller.scoreboardContainerTarget.style.display).toBe("block")
  })

  it("finished websocket payload hides the embedded scoreboard", () => {
    const controller = buildController()

    controller.updateDisplayElements({
      winner_id: 11,
      score: "",
      win_type: "",
      finished: 1
    })

    expect(controller.winnerTarget.textContent).toBe("ID: 11")
    expect(controller.scoreTarget.textContent).toBe("-")
    expect(controller.winTypeTarget.textContent).toBe("-")
    expect(controller.finishedTarget.textContent).toBe("Yes")
    expect(controller.scoreboardContainerTarget.style.display).toBe("none")
  })

  it("disconnect unsubscribes from the match channel", () => {
    const controller = buildController()
    const subscription = { unsubscribe: vi.fn() }
    controller.matchSubscription = subscription

    controller.disconnect()

    expect(subscription.unsubscribe).toHaveBeenCalledTimes(1)
    expect(controller.matchSubscription).toBe(null)
  })
})
