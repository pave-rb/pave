import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        this.element.style.animation = "card-remove 260ms cubic-bezier(0.4, 0, 0.2, 1) forwards"
        this.element.addEventListener("animationend", this.remove.bind(this), { once: true })
        this.timeout = setTimeout(() => this.remove(), 320)
      })
    })
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  remove() {
    if (this.timeout) clearTimeout(this.timeout)
    this.element.remove()
  }
}
