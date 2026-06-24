import { Controller } from "@hotwired/stimulus"

// Backoffice secret field controller.
// Handles reveal, copy, and clear interactions without exposing plaintext by default.
export default class extends Controller {
  static targets = ["maskedValue", "input", "clear", "sourceBadge", "revealButton", "copyButton"]
  static values = { source: String, present: Boolean }

  connect() {
    this._originalMaskedText = this.hasMaskedValueTarget ? this.maskedValueTarget.textContent.trim() : ""
  }

  reveal(event) {
    event.preventDefault()
    if (!this.hasInputTarget) return

    const button = event.currentTarget
    const isRevealed = button.dataset.revealed === "true"

    if (isRevealed) {
      this.inputTarget.setAttribute("type", "password")
      button.textContent = "Reveal"
      button.dataset.revealed = "false"
      if (this.hasMaskedValueTarget) this.maskedValueTarget.textContent = this._originalMaskedText
    } else {
      this.inputTarget.setAttribute("type", "text")
      button.textContent = "Hide"
      button.dataset.revealed = "true"
      if (this.hasMaskedValueTarget && this.inputTarget.value) {
        this.maskedValueTarget.textContent = this.inputTarget.value
      }
    }
  }

  copy(event) {
    event.preventDefault()
    if (!navigator.clipboard) return

    const text = this.copyValue()
    if (!text) return

    const button = event.currentTarget
    const originalText = button.textContent
    const copiedText = button.dataset.copiedText || "Copied!"

    navigator.clipboard.writeText(text).then(() => {
      button.textContent = copiedText
      setTimeout(() => {
        button.textContent = originalText
      }, 1500)
    })
  }

  copyValue() {
    if (this.hasInputTarget && this.inputTarget.value) return this.inputTarget.value
    return ""
  }

  openEdit() {
    if (this.hasInputTarget) {
      this.inputTarget.focus()
    }
  }

  toggleClear() {
    if (!this.hasInputTarget || !this.hasClearTarget) return

    if (this.clearTarget.checked) {
      this.inputTarget.value = ""
      this.inputTarget.disabled = true
    } else {
      this.inputTarget.disabled = false
    }
  }
}
