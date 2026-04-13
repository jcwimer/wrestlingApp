import { beforeEach, describe, expect, it, vi } from "vitest"
import MatchDataController from "../../../app/assets/javascripts/controllers/match_data_controller.js"

function makeTarget(value = "") {
  return {
    value,
    innerText: "",
    addEventListener: vi.fn(),
    classList: {
      add: vi.fn(),
      remove: vi.fn()
    }
  }
}

function buildController() {
  const controller = new MatchDataController()
  controller.tournamentIdValue = 8
  controller.boutNumberValue = 1001
  controller.matchIdValue = 22
  controller.w1StatTarget = makeTarget("Initial W1")
  controller.w2StatTarget = makeTarget("Initial W2")
  controller.statusIndicatorTarget = makeTarget()
  return controller
}

describe("match data controller", () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    vi.spyOn(Date.prototype, "toISOString").mockReturnValue("2026-04-10T00:00:00.000Z")
    global.localStorage = {
      getItem: vi.fn(() => null),
      setItem: vi.fn()
    }
    global.window = {
      App: null
    }
    global.document = {
      getElementById: vi.fn(() => null)
    }
    global.setTimeout = vi.fn((fn) => {
      fn()
      return 1
    })
    global.clearTimeout = vi.fn()
    global.setInterval = vi.fn(() => 123)
    global.clearInterval = vi.fn()
  })

  it("connect initializes wrestler state, localStorage, textarea handlers, and subscription", () => {
    const controller = buildController()
    controller.initializeFromLocalStorage = vi.fn()
    controller.setupSubscription = vi.fn()

    controller.connect()

    expect(controller.w1.stats).toBe("Initial W1")
    expect(controller.w2.stats).toBe("Initial W2")
    expect(controller.w1StatTarget.addEventListener).toHaveBeenCalledWith("input", expect.any(Function))
    expect(controller.w2StatTarget.addEventListener).toHaveBeenCalledWith("input", expect.any(Function))
    expect(controller.initializeFromLocalStorage).toHaveBeenCalledTimes(1)
    expect(controller.setupSubscription).toHaveBeenCalledWith(22)
  })

  it("generates tournament and bout scoped localStorage keys", () => {
    const controller = buildController()

    expect(controller.generateKey("w1")).toBe("w1-8-1001")
    expect(controller.generateKey("w2")).toBe("w2-8-1001")
  })

  it("updateStats updates textareas, localStorage, and sends websocket stat payloads", () => {
    const controller = buildController()
    controller.connect()
    controller.matchSubscription = { perform: vi.fn() }

    controller.updateStats(controller.w1, "T3")

    expect(controller.w1.stats).toBe("Initial W1T3 ")
    expect(controller.w1StatTarget.value).toBe("Initial W1T3 ")
    expect(localStorage.setItem).toHaveBeenCalledWith(
      "w1-8-1001",
      expect.stringContaining('"stats":"Initial W1T3 "')
    )
    expect(controller.matchSubscription.perform).toHaveBeenCalledWith("send_stat", {
      new_w1_stat: "Initial W1T3 "
    })
  })

  it("textarea input saves local state and marks pending sync when disconnected", () => {
    const controller = buildController()
    controller.connect()
    controller.isConnected = false
    controller.matchSubscription = { perform: vi.fn() }

    controller.handleTextAreaInput({ value: "Manual stat" }, controller.w2)

    expect(controller.w2.stats).toBe("Manual stat")
    expect(controller.pendingLocalSync.w2).toBe(true)
    expect(localStorage.setItem).toHaveBeenCalledWith(
      "w2-8-1001",
      expect.stringContaining('"stats":"Manual stat"')
    )
    expect(controller.matchSubscription.perform).toHaveBeenCalledWith("send_stat", {
      new_w2_stat: "Manual stat"
    })
  })

  it("loads persisted localStorage stats and timers into the textareas", () => {
    const controller = buildController()
    localStorage.getItem = vi.fn((key) => {
      if (key === "w1-8-1001") {
        return JSON.stringify({
          stats: "Saved W1",
          updated_at: "timestamp",
          timers: {
            injury: { time: 5, startTime: null, interval: null },
            blood: { time: 0, startTime: null, interval: null }
          }
        })
      }
      return null
    })

    controller.connect()

    expect(controller.w1.stats).toBe("Saved W1")
    expect(controller.w1StatTarget.value).toBe("Saved W1")
    expect(controller.w1.timers.injury.time).toBe(5)
  })

  it("subscription callbacks update status, request sync, and apply received stats", () => {
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
    window.App = global.App

    controller.connect()
    controller.w1.stats = "Local W1"
    controller.w2.stats = "Local W2"
    callbacks.connected()

    expect(controller.isConnected).toBe(true)
    expect(controller.statusIndicatorTarget.innerText).toBe("Connected: Stats will update in real-time.")
    expect(subscription.perform).toHaveBeenCalledWith("send_stat", {
      new_w1_stat: "Local W1",
      new_w2_stat: "Local W2"
    })

    controller.pendingLocalSync.w1 = false
    controller.pendingLocalSync.w2 = false
    callbacks.received({ w1_stat: "Remote W1", w2_stat: "Remote W2" })

    expect(controller.w1StatTarget.value).toBe("Remote W1")
    expect(controller.w2StatTarget.value).toBe("Remote W2")

    callbacks.disconnected()
    expect(controller.isConnected).toBe(false)
    expect(controller.statusIndicatorTarget.innerText).toBe("Disconnected: Stats updates paused.")
  })

  it("setupSubscription reports websocket unavailable when ActionCable is missing", () => {
    const controller = buildController()
    controller.connect()

    expect(controller.statusIndicatorTarget.innerText).toBe("Error: WebSockets unavailable. Stats won't update in real-time.")
    expect(controller.statusIndicatorTarget.classList.add).toHaveBeenCalledWith("alert-danger")
  })
})
