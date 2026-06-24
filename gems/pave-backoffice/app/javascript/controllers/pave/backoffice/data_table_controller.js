import { Controller } from "@hotwired/stimulus"

// Backoffice data table controller.
// Watches the nearest enclosing Turbo Frame for Turbo's busy state and toggles a
// loading overlay. Frame errors reveal an error target with a retry action.
export default class extends Controller {
  static targets = ["loading", "error"]

  connect() {
    this.frame = this.element.closest("turbo-frame")
    if (!this.frame) return

    this.setBusy(this.frame.hasAttribute("data-turbo-busy"))

    this._onError = () => this.showError()
    this.frame.addEventListener("turbo:frame-error", this._onError)

    this._observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.attributeName === "data-turbo-busy") {
          this.setBusy(this.frame.hasAttribute("data-turbo-busy"))
        }
      })
    })
    this._observer.observe(this.frame, { attributes: true, attributeFilter: ["data-turbo-busy"] })
  }

  setBusy(busy) {
    this.element.toggleAttribute("data-backoffice-data-table-loading", busy)
    if (this.hasLoadingTarget) this.loadingTarget.hidden = !busy
    if (busy && this.hasErrorTarget) this.errorTarget.hidden = true
  }

  showError() {
    this.setBusy(false)
    if (this.hasErrorTarget) this.errorTarget.hidden = false
  }

  retry() {
    this.frame?.reload()
  }

  disconnect() {
    this._observer?.disconnect()
    this.frame?.removeEventListener("turbo:frame-error", this._onError)
  }
}
