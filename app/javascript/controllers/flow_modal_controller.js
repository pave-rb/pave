import { Controller } from "@hotwired/stimulus"

// Modal lifecycle for guided flows injected into #modal_container.
// Mirrors the existing error/form modal animation while adding a small focus trap.
export default class extends Controller {
  static targets = ["panel"]

  connect() {
    this._previousFocus = document.activeElement
    this._focusableSelector = "a[href], button:not([disabled]), textarea, input:not([type='hidden']), select, [tabindex]:not([tabindex='-1'])"

    this.element.style.opacity = "0"
    if (this.hasPanelTarget) this.panelTarget.style.translate = "0 20px"

    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        this.element.style.transition = "opacity 200ms cubic-bezier(0.4, 0, 0.2, 1)"
        this.element.style.opacity = "1"
        if (this.hasPanelTarget) {
          this.panelTarget.style.transition = "translate 250ms cubic-bezier(0.4, 0, 0.2, 1)"
          this.panelTarget.style.translate = "0 0"
        }
      })
    })

    this._onKeydown = this.trapFocus.bind(this)
    this.element.addEventListener("keydown", this._onKeydown)

    setTimeout(() => {
      this.element.querySelector("[data-flow-modal-initial-focus], input:not([type='hidden']), button:not([disabled]), a[href]")?.focus()
    }, 260)
  }

  close() {
    this.element.style.transition = "opacity 150ms cubic-bezier(0.4, 0, 0.2, 1)"
    this.element.style.opacity = "0"
    this.element.addEventListener("transitionend", () => {
      const container = document.getElementById("modal_container")
      if (container) container.innerHTML = ""
      this._previousFocus?.focus()
    }, { once: true })
  }

  trapFocus(event) {
    if (event.key !== "Tab") return

    const focusable = Array.from(this.element.querySelectorAll(this._focusableSelector))
      .filter((element) => element.offsetParent !== null)
    if (focusable.length === 0) return

    const first = focusable[0]
    const last = focusable[focusable.length - 1]

    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault()
      last.focus()
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault()
      first.focus()
    }
  }

  disconnect() {
    this.element.removeEventListener("keydown", this._onKeydown)
    this._previousFocus?.focus()
  }
}
