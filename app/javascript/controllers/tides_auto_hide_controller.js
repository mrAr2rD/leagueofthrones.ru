import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static values = {
    delay: { type: Number, default: 2000 },
    url: String
  }

  connect() {
    this.timer = window.setTimeout(() => {
      Turbo.visit(this.urlValue, { action: "replace" })
    }, this.delayValue)
  }

  disconnect() {
    window.clearTimeout(this.timer)
  }
}
