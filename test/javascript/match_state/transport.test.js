import { describe, expect, it, vi } from "vitest"
import {
  cleanupExpiredLocalStorage,
  loadJson,
  MATCH_DATA_TTL_MS,
  performIfChanged,
  removeKey,
  saveJson,
  SHORT_LIVED_TTL_MS
} from "match-state-transport"

describe("match state transport", () => {
  it("loads saved json from storage", () => {
    const storage = {
      getItem: vi.fn(() => '{"score":3}')
    }

    expect(loadJson(storage, "match-state:1:1001")).toEqual({ score: 3 })
    expect(storage.getItem).toHaveBeenCalledWith("match-state:1:1001")
  })

  it("returns null when stored json is invalid", () => {
    const storage = {
      getItem: vi.fn(() => "{not-json")
    }

    expect(loadJson(storage, "bad")).toBe(null)
  })

  it("saves and removes json values in storage", () => {
    const storage = {
      setItem: vi.fn(),
      removeItem: vi.fn()
    }

    expect(saveJson(storage, "key", { score: 5 })).toBe(true)
    expect(storage.setItem).toHaveBeenCalledWith("key", '{"score":5}')

    expect(removeKey(storage, "key")).toBe(true)
    expect(storage.removeItem).toHaveBeenCalledWith("key")
  })

  it("saves and loads expiring json values", () => {
    vi.spyOn(Date, "now").mockReturnValue(1_000)
    const storage = {
      getItem: vi.fn(),
      setItem: vi.fn(),
      removeItem: vi.fn()
    }

    expect(saveJson(storage, "match-state:1:1001", { score: 5 }, { ttlMs: MATCH_DATA_TTL_MS })).toBe(true)
    const savedValue = JSON.parse(storage.setItem.mock.calls[0][1])
    expect(savedValue.expiresAt).toBe(1_000 + MATCH_DATA_TTL_MS)

    storage.getItem.mockReturnValue(JSON.stringify(savedValue))
    expect(loadJson(storage, "match-state:1:1001")).toEqual({ score: 5 })
  })

  it("removes expired json values when loading", () => {
    vi.spyOn(Date, "now").mockReturnValue(10_000)
    const storage = {
      getItem: vi.fn(() => JSON.stringify({
        __wrestlingAppStorage: true,
        expiresAt: 9_000,
        value: { score: 5 }
      })),
      removeItem: vi.fn()
    }

    expect(loadJson(storage, "match-state:1:1001")).toBe(null)
    expect(storage.removeItem).toHaveBeenCalledWith("match-state:1:1001")
  })

  it("cleans expired app localStorage keys and leaves unrelated keys alone", () => {
    const values = {
      "match-state:1:1001": JSON.stringify({
        __wrestlingAppStorage: true,
        expiresAt: 1_000,
        value: { score: 5 }
      }),
      "mat-selected-bout:1:2": JSON.stringify({
        __wrestlingAppStorage: true,
        expiresAt: 50_000,
        value: { boutNumber: 1001 }
      }),
      "unrelated": JSON.stringify({
        __wrestlingAppStorage: true,
        expiresAt: 1_000,
        value: "keep"
      })
    }
    const keys = Object.keys(values)
    const storage = {
      length: keys.length,
      key: vi.fn((index) => keys[index]),
      getItem: vi.fn((key) => values[key]),
      setItem: vi.fn(),
      removeItem: vi.fn()
    }

    cleanupExpiredLocalStorage(storage, 10_000)

    expect(storage.removeItem).toHaveBeenCalledWith("match-state:1:1001")
    expect(storage.removeItem).not.toHaveBeenCalledWith("mat-selected-bout:1:2")
    expect(storage.removeItem).not.toHaveBeenCalledWith("unrelated")
  })

  it("removes stale legacy stat data using its updated timestamp", () => {
    const keys = ["w1-8-1001"]
    const storage = {
      length: 1,
      key: vi.fn((index) => keys[index]),
      getItem: vi.fn(() => JSON.stringify({
        stats: "old",
        updated_at: "2026-04-01T00:00:00.000Z"
      })),
      setItem: vi.fn(),
      removeItem: vi.fn()
    }

    cleanupExpiredLocalStorage(storage, Date.parse("2026-04-13T00:00:00.000Z"))

    expect(storage.removeItem).toHaveBeenCalledWith("w1-8-1001")
  })

  it("adds expiration to legacy app values that are still valid", () => {
    const keys = ["mat-last-match-result:8:3"]
    const storage = {
      length: 1,
      key: vi.fn((index) => keys[index]),
      getItem: vi.fn(() => JSON.stringify("Result text")),
      setItem: vi.fn(),
      removeItem: vi.fn()
    }

    cleanupExpiredLocalStorage(storage, 2_000)

    const wrappedValue = JSON.parse(storage.setItem.mock.calls[0][1])
    expect(storage.setItem.mock.calls[0][0]).toBe("mat-last-match-result:8:3")
    expect(wrappedValue.value).toBe("Result text")
    expect(wrappedValue.expiresAt).toBe(2_000 + SHORT_LIVED_TTL_MS)
  })

  it("only performs subscription actions when the payload changes", () => {
    const subscription = {
      perform: vi.fn()
    }

    const firstSerialized = performIfChanged(subscription, "send_stat", { new_w1_stat: "T3" }, null)
    const secondSerialized = performIfChanged(subscription, "send_stat", { new_w1_stat: "T3" }, firstSerialized)
    const thirdSerialized = performIfChanged(subscription, "send_stat", { new_w1_stat: "T3 E1" }, secondSerialized)

    expect(subscription.perform).toHaveBeenCalledTimes(2)
    expect(subscription.perform).toHaveBeenNthCalledWith(1, "send_stat", { new_w1_stat: "T3" })
    expect(subscription.perform).toHaveBeenNthCalledWith(2, "send_stat", { new_w1_stat: "T3 E1" })
    expect(firstSerialized).toBe('{"new_w1_stat":"T3"}')
    expect(secondSerialized).toBe(firstSerialized)
    expect(thirdSerialized).toBe('{"new_w1_stat":"T3 E1"}')
  })
})
