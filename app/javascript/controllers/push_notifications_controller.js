import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status", "enableButton", "disableButton"]

  static values = {
    publicKey: String,
    enabled: Boolean,
    createPath: String,
    destroyPath: String,
    preferencePath: String
  }

  connect() {
    if (!this.supported || !this.publicKeyValue) return

    this.registerServiceWorker()
    this.refreshControls()
  }

  async registerServiceWorker() {
    try {
      this.registration = await navigator.serviceWorker.register("/service-worker.js")

      if (this.enabledValue && Notification.permission === "granted") {
        const synced = await this.ensureSubscription()
        if (!synced) await this.savePreference(false, Notification.permission)
        this.enabledValue = synced
      } else if (Notification.permission === "denied") {
        await this.savePreference(false, "denied")
      }
      this.refreshControls()
    } catch (error) {
      console.warn("[PushNotifications] service worker registration failed", error)
    }
  }

  async enable() {
    if (!this.supported || !this.publicKeyValue) {
      await this.savePreference(false, "unsupported")
      this.refreshControls()
      return
    }

    try {
      this.registration ||= await navigator.serviceWorker.register("/service-worker.js")
      const permission = await Notification.requestPermission()

      if (permission !== "granted") {
        await this.savePreference(false, permission)
        this.refreshControls()
        return
      }

      const synced = await this.ensureSubscription()
      if (!synced) await this.savePreference(false, permission)
      this.enabledValue = synced
      this.refreshControls()
    } catch (error) {
      console.warn("[PushNotifications] enable failed", error)
      await this.savePreference(false, "default")
      this.refreshControls()
    }
  }

  async disable() {
    if (!this.supported || !this.publicKeyValue) {
      await this.savePreference(false, "unsupported")
      this.refreshControls()
      return
    }

    try {
      this.registration ||= await navigator.serviceWorker.register("/service-worker.js")
      const subscription = await this.registration.pushManager.getSubscription()
      if (subscription) {
        await this.destroySubscription(subscription)
        await subscription.unsubscribe()
      } else {
        await this.savePreference(false, Notification.permission)
      }

      this.enabledValue = false
      this.refreshControls()
    } catch (error) {
      console.warn("[PushNotifications] disable failed", error)
    }
  }

  async ensureSubscription() {
    const existing = await this.registration.pushManager.getSubscription()
    const subscription = existing || await this.registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: this.urlBase64ToUint8Array(this.publicKeyValue)
    })

    return this.saveSubscription(subscription)
  }

  async saveSubscription(subscription) {
    const response = await fetch(this.createPathValue, {
      method: "POST",
      credentials: "same-origin",
      headers: this.headers,
      body: JSON.stringify({ subscription: subscription.toJSON() })
    })

    if (!response.ok) {
      console.warn("[PushNotifications] subscription sync failed", response.status)
      return false
    }

    this.enabledValue = true
    return true
  }

  async destroySubscription(subscription) {
    await fetch(this.destroyPathValue, {
      method: "DELETE",
      credentials: "same-origin",
      headers: this.headers,
      body: JSON.stringify({ endpoint: subscription.endpoint, permission: Notification.permission })
    })
  }

  async savePreference(enabled, permission) {
    if (!this.preferencePathValue) return

    const response = await fetch(this.preferencePathValue, {
      method: "PATCH",
      credentials: "same-origin",
      headers: this.headers,
      body: JSON.stringify({ enabled, permission })
    })

    if (!response.ok) return

    const data = await response.json()
    this.enabledValue = data.push_notifications_enabled === true
  }

  urlBase64ToUint8Array(value) {
    const padding = "=".repeat((4 - value.length % 4) % 4)
    const base64 = (value + padding).replace(/-/g, "+").replace(/_/g, "/")
    const rawData = window.atob(base64)
    const output = new Uint8Array(rawData.length)

    for (let i = 0; i < rawData.length; i += 1) {
      output[i] = rawData.charCodeAt(i)
    }

    return output
  }

  get supported() {
    return "serviceWorker" in navigator && "PushManager" in window && "Notification" in window
  }

  get headers() {
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content || ""
    }
  }

  refreshControls() {
    const permission = this.supported ? Notification.permission : "unsupported"
    const enabled = this.enabledValue && permission === "granted"

    this.enableButtonTargets.forEach((button) => {
      button.disabled = enabled
      button.classList.toggle("opacity-60", enabled)
    })
    this.disableButtonTargets.forEach((button) => {
      button.disabled = !this.enabledValue
      button.classList.toggle("opacity-60", !this.enabledValue)
    })
    this.statusTargets.forEach((target) => {
      const key = enabled ? "enabled" : permission === "denied" ? "denied" : this.enabledValue ? "pending" : "disabled"
      target.textContent = target.dataset[`pushNotifications${this.camelize(key)}Label`] || target.textContent
    })
  }

  camelize(value) {
    return value.replace(/(^|_)([a-z])/g, (_match, _separator, letter) => letter.toUpperCase())
  }
}
