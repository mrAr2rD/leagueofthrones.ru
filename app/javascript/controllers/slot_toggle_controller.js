import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "select"]

  toggle(event) {
    const select = event.target
    const row = select.closest("[data-slot-toggle-target='row']")
    if (!row) return

    const empty = select.value === ""

    row.classList.toggle("bg-gray-50", empty)
    row.classList.toggle("opacity-50", empty)
  }
}
