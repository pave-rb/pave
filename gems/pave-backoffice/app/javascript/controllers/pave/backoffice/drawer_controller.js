import { Controller } from "@hotwired/stimulus"

// Backoffice drawer controller.
// Handles slide-in animation, close on Escape, and focus return.
export default class extends Controller {
  static targets = ["panel", "content"]
  static values = { open: { type: Boolean, default: true } }

  connect() {
    this._previousFocus = document.activeElement

    if (this.openValue) {
      this.panelTarget.style.translate = "100%"
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          this.panelTarget.style.transition = "translate 250ms cubic-bezier(0.4, 0, 0.2, 1)"
          this.panelTarget.style.translate = "0"
        })
      })
    }

    this._onKeydown = this.handleKeydown.bind(this)
    this.element.addEventListener("keydown", this._onKeydown)
  }

  backdropClose(event) {
    if (event.target === this.element) {
      event.preventDefault()
      this.close()
    }
  }

  close() {
    if (this.hasPanelTarget) {
      this.panelTarget.style.transition = "translate 200ms cubic-bezier(0.4, 0, 0.2, 1)"
      this.panelTarget.style.translate = "100%"
      this.panelTarget.addEventListener("transitionend", () => {
        this.element.style.opacity = "0"
        this.element.addEventListener("transitionend", () => {
          this.element.remove()
          this._previousFocus?.focus()
        }, { once: true })
      }, { once: true })
    } else {
      this.element.remove()
      this._previousFocus?.focus()
    }
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
