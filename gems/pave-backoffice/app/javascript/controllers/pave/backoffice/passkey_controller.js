import { Controller } from "@hotwired/stimulus"

function base64urlToArrayBuffer(value) {
  const padding = "=".repeat((4 - (value.length % 4)) % 4)
  const base64 = `${value}${padding}`.replace(/-/g, "+").replace(/_/g, "/")
  const binary = window.atob(base64)
  const bytes = Uint8Array.from(binary, (char) => char.charCodeAt(0))
  return bytes.buffer
}

function arrayBufferToBase64url(value) {
  if (!value) return null

  const bytes = value instanceof Uint8Array ? value : new Uint8Array(value)
  let binary = ""
  bytes.forEach((byte) => {
    binary += String.fromCharCode(byte)
  })

  return window.btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "")
}

function parseCreationOptionsFromJSON(options) {
  if (window.PublicKeyCredential?.parseCreationOptionsFromJSON) {
    return window.PublicKeyCredential.parseCreationOptionsFromJSON(options)
  }

  const parsed = JSON.parse(JSON.stringify(options))
  parsed.challenge = base64urlToArrayBuffer(parsed.challenge)
  parsed.user.id = base64urlToArrayBuffer(parsed.user.id)
  parsed.excludeCredentials = (parsed.excludeCredentials || []).map((credential) => ({
    ...credential,
    id: base64urlToArrayBuffer(credential.id)
  }))

  return parsed
}

function parseRequestOptionsFromJSON(options) {
  if (window.PublicKeyCredential?.parseRequestOptionsFromJSON) {
    return window.PublicKeyCredential.parseRequestOptionsFromJSON(options)
  }

  const parsed = JSON.parse(JSON.stringify(options))
  parsed.challenge = base64urlToArrayBuffer(parsed.challenge)
  parsed.allowCredentials = (parsed.allowCredentials || []).map((credential) => ({
    ...credential,
    id: base64urlToArrayBuffer(credential.id)
  }))

  return parsed
}

function publicKeyCredentialToJSON(credential) {
  const response = credential.response
  const payload = {
    id: credential.id,
    rawId: arrayBufferToBase64url(credential.rawId),
    type: credential.type,
    authenticatorAttachment: credential.authenticatorAttachment || null,
    clientExtensionResults: credential.getClientExtensionResults()
  }

  if (typeof AuthenticatorAttestationResponse !== "undefined" && response instanceof AuthenticatorAttestationResponse) {
    payload.response = {
      clientDataJSON: arrayBufferToBase64url(response.clientDataJSON),
      attestationObject: arrayBufferToBase64url(response.attestationObject),
      transports: typeof response.getTransports === "function" ? response.getTransports() : []
    }
  } else {
    payload.response = {
      clientDataJSON: arrayBufferToBase64url(response.clientDataJSON),
      authenticatorData: arrayBufferToBase64url(response.authenticatorData),
      signature: arrayBufferToBase64url(response.signature),
      userHandle: response.userHandle ? arrayBufferToBase64url(response.userHandle) : null
    }
  }

  return payload
}

export default class extends Controller {
  static targets = ["button", "error", "label"]
  static values = {
    optionsUrl: String,
    submitUrl: String,
    unsupportedMessage: String,
    genericErrorMessage: String,
    labelRequiredMessage: String
  }

  async register() {
    if (!this.supported()) {
      this.showError(this.unsupportedMessageValue)
      return
    }

    const label = this.hasLabelTarget ? this.labelTarget.value.trim() : ""
    if (this.hasLabelTarget && !label) {
      this.showError(this.labelRequiredMessageValue)
      return
    }

    await this.perform("register", { label })
  }

  async authenticate() {
    if (!this.supported()) {
      this.showError(this.unsupportedMessageValue)
      return
    }

    await this.perform("authenticate")
  }

  async perform(mode, extraPayload = {}) {
    this.setBusy(true, mode)
    this.hideError()

    try {
      const options = await this.postJSON(this.optionsUrlValue)
      const publicKey = mode === "register" ? parseCreationOptionsFromJSON(options) : parseRequestOptionsFromJSON(options)
      const credential = mode === "register" ? await navigator.credentials.create({ publicKey }) : await navigator.credentials.get({ publicKey })
      const result = await this.postJSON(this.submitUrlValue, {
        ...extraPayload,
        public_key_credential: publicKeyCredentialToJSON(credential)
      })

      if (result.redirect_url && window.Turbo?.visit) window.Turbo.visit(result.redirect_url)
    } catch (error) {
      this.showError(error.message || this.genericErrorMessageValue)
    } finally {
      this.setBusy(false)
    }
  }

  async postJSON(url, body = {}) {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken()
      },
      body: JSON.stringify(body)
    })

    const text = await response.text()
    const data = text ? JSON.parse(text) : {}

    if (!response.ok) {
      if (data.redirect_url && window.Turbo?.visit) window.Turbo.visit(data.redirect_url)
      throw new Error(data.error || this.genericErrorMessageValue)
    }

    return data
  }

  setBusy(busy, mode = null) {
    if (!this.hasButtonTarget) return

    this.buttonTarget.disabled = busy
    if (!this.buttonTarget.dataset.originalText) this.buttonTarget.dataset.originalText = this.buttonTarget.textContent.trim()

    if (busy) {
      this.buttonTarget.textContent = mode === "register" ? this.buttonTarget.dataset.registerLoadingText : this.buttonTarget.dataset.authenticateLoadingText
      return
    }

    this.buttonTarget.textContent = this.buttonTarget.dataset.originalText
  }

  showError(message) {
    if (!this.hasErrorTarget) return

    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
  }

  hideError() {
    if (!this.hasErrorTarget) return

    this.errorTarget.textContent = ""
    this.errorTarget.classList.add("hidden")
  }

  csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content || ""
  }

  supported() {
    return typeof window.PublicKeyCredential !== "undefined" && !!navigator.credentials
  }
}
