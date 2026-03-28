import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "status"]

  toggle() {
    this.statusTarget.classList.toggle("hidden", this.inputTarget.value !== "")
  }
}
