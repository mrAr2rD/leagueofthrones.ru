import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "select"]

  toggle(event) {
    const select = event.target
    const row = select.closest("tr")
    const empty = select.value === ""

    row.classList.toggle("bg-gray-50", empty)
    row.classList.toggle("opacity-50", empty)
  }
}
