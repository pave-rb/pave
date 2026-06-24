import { Controller } from "@hotwired/stimulus"

// Backoffice confirmation modal controller.
// Blocks submit until optional reason/confirmation input requirements are satisfied.
export default class extends Controller {
  static targets = ["panel", "form", "reason", "confirmation", "submit"]
  static values = { confirmationValue: String }

  connect() {
    this._previousFocus = document.activeElement

    this.element.style.opacity = "0"
    if (this.hasPanelTarget) this.panelTarget.style.translate = "0 20px"

    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        this.element.style.transition = "opacity 200ms cubic-bezier(0.4, 0, 0.2, 1)"
        this.element.style.opacity = "1"
        if (this.hasPanelTarget) {
          this.panelTarget.style.transition = "translate 250ms cubic-bezier(0.4, 0, 0.2, 1)"
          this.panelTarget.style.translate = "0"
        }
      })
    })

    this._onKeydown = this.handleKeydown.bind(this)
    this.element.addEventListener("keydown", this._onKeydown)

    setTimeout(() => {
      this.element.querySelector("input:not([type='hidden']), textarea, select, button")?.focus()
    }, 260)

    this.validate()
  }

  close() {
    this.element.style.transition = "opacity 150ms cubic-bezier(0.4, 0, 0.2, 1)"
    this.element.style.opacity = "0"
    this.element.addEventListener("transitionend", () => {
      this.element.remove()
      this._previousFocus?.focus()
    }, { once: true })
  }

  validate() {
    if (!this.hasSubmitTarget) return

    let enabled = true

    if (this.hasReasonTarget && this.reasonTarget.required) {
      enabled = enabled && this.reasonTarget.value.trim().length > 0
    }

    if (this.hasConfirmationTarget) {
      const expected = (this.confirmationTarget.dataset.confirmationValue || this.confirmationValueValue || "").trim()
      enabled = enabled && this.confirmationTarget.value.trim() === expected
    }

    this.submitTarget.disabled = !enabled
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      event.preventDefault()
      this.close()
    }
  }

  disconnect() {
    this.element.removeEventListener("keydown", this._onKeydown)
    this._previousFocus?.focus()
  }
}
