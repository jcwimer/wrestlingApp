export const MATCH_DATA_TTL_MS = 48 * 60 * 60 * 1000
export const SHORT_LIVED_TTL_MS = 4 * 60 * 60 * 1000

const STORAGE_MARKER = "__wrestlingAppStorage"

export function loadJson(storage, key) {
  try {
    const rawValue = storage.getItem(key)
    if (!rawValue) return null
    const parsed = JSON.parse(rawValue)
    if (!isExpiringStorageValue(parsed)) return parsed
    if (isExpired(parsed)) {
      storage.removeItem(key)
      return null
    }
    return parsed.value
  } catch (_error) {
    return null
  }
}

export function saveJson(storage, key, value, options = {}) {
  try {
    const valueToStore = options.ttlMs
      ? expiringStorageValue(value, options.ttlMs)
      : value
    storage.setItem(key, JSON.stringify(valueToStore))
    return true
  } catch (_error) {
    return false
  }
}

export function removeKey(storage, key) {
  try {
    storage.removeItem(key)
    return true
  } catch (_error) {
    return false
  }
}

export function performIfChanged(subscription, action, payload, lastSerializedPayload) {
  if (!subscription) return lastSerializedPayload

  const serializedPayload = JSON.stringify(payload)
  if (serializedPayload === lastSerializedPayload) {
    return lastSerializedPayload
  }

  subscription.perform(action, payload)
  return serializedPayload
}

export function cleanupExpiredLocalStorage(storage, now = Date.now()) {
  try {
    const keys = []
    for (let index = 0; index < storage.length; index += 1) {
      const key = storage.key(index)
      if (key && ttlForStorageKey(key)) keys.push(key)
    }

    keys.forEach((key) => cleanupStorageKey(storage, key, now))
  } catch (_error) {
  }
}

function cleanupStorageKey(storage, key, now) {
  const ttlMs = ttlForStorageKey(key)
  if (!ttlMs) return

  const rawValue = storage.getItem(key)
  if (!rawValue) return

  try {
    const parsed = JSON.parse(rawValue)
    if (isExpiringStorageValue(parsed)) {
      if (isExpired(parsed, now)) storage.removeItem(key)
      return
    }

    const legacyUpdatedAt = Date.parse(parsed?.updated_at)
    if (legacyUpdatedAt && now - legacyUpdatedAt > ttlMs) {
      storage.removeItem(key)
      return
    }

    storage.setItem(key, JSON.stringify(expiringStorageValue(parsed, ttlMs, legacyUpdatedAt || now)))
  } catch (_error) {
    storage.removeItem(key)
  }
}

function expiringStorageValue(value, ttlMs, storedAt = Date.now()) {
  return {
    [STORAGE_MARKER]: true,
    expiresAt: storedAt + ttlMs,
    value
  }
}

function isExpiringStorageValue(value) {
  return value && typeof value === "object" && value[STORAGE_MARKER] === true
}

function isExpired(value, now = Date.now()) {
  return Number(value.expiresAt) <= now
}

function ttlForStorageKey(key) {
  if (key.startsWith("match-state:")) return MATCH_DATA_TTL_MS
  if (/^w[12]-\d+-\d+$/.test(key)) return MATCH_DATA_TTL_MS
  if (key.startsWith("mat-selected-bout:")) return SHORT_LIVED_TTL_MS
  if (key.startsWith("mat-last-match-result:")) return SHORT_LIVED_TTL_MS
  return null
}
