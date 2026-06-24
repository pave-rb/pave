import { Controller } from "@hotwired/stimulus"

// Backoffice filter bar controller.
// GET forms are submitted inside a Turbo Frame so table content updates without
// a full page navigation. Select/checkbox changes submit immediately; text and
// date inputs submit after a short debounce. Query params remain shareable
// because the form advances the URL.
export default class extends Controller {
  static targets = ["form"]
  static values = {
    frame: String,
    autoSubmit: { type: Boolean, default: true }
  }

  connect() {
    if (this.hasFormTarget) {
      if (this.frameValue) {
        this.formTarget.setAttribute("data-turbo-frame", this.frameValue)
        this.formTarget.setAttribute("data-turbo-action", "advance")
      }

      if (this.autoSubmitValue) {
        this.formTarget.querySelectorAll("select, input[type='checkbox']").forEach((element) => {
          element.addEventListener("change", () => this.submit())
        })

        this._debouncedInput = this.debounce(() => this.submit(), 350)
        this.formTarget.querySelectorAll("input[type='text'], input[type='search'], input[type='date'], input[type='email']").forEach((element) => {
          element.addEventListener("input", this._debouncedInput)
        })
      }
    }
  }

  submit() {
    this.formTarget?.requestSubmit()
  }

  debounce(callback, wait) {
    let timeout
    return (...args) => {
      clearTimeout(timeout)
      timeout = setTimeout(() => callback.apply(this, args), wait)
    }
  }

  disconnect() {
    this.formTarget?.querySelectorAll("input, select, textarea").forEach((element) => {
      element.replaceWith(element.cloneNode(true))
    })
  }
}
