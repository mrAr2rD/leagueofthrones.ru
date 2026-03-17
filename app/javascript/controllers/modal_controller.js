import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "frame"]

  close() {
    this.element.classList.add("hidden")
    if (this.hasFrameTarget) {
      this.frameTarget.innerHTML = ""
    }
  }

  closeBackground(event) {
    if (event.target === this.element) {
      this.close()
    }
  }

  closeEscape(event) {
    if (event.key === "Escape" && !this.element.classList.contains("hidden")) {
      this.close()
    }
  }

  stopPropagation(event) {
    event.stopPropagation()
  }
}
