import { Controller } from "@hotwired/stimulus"

const PLACE_POINTS = { 1: 15, 2: 12, 3: 10, 4: 8, 5: 6, 6: 4, 7: 2, 8: 1 }

export default class extends Controller {
  static targets = ["row"]

  calculate(event) {
    const row = event.target.closest("[data-points-calculator-target='row']")
    if (!row) return

    const place = parseInt(row.querySelector("[data-points-calculator-target='place']")?.value) || 0
    const capitals = parseInt(row.querySelector("[data-points-calculator-target='capitals']")?.value) || 0
    const dragons = parseInt(row.querySelector("[data-points-calculator-target='dragons']")?.value) || 0
    const castles = parseInt(row.querySelector("[data-points-calculator-target='castles']")?.value) || 0

    const base = PLACE_POINTS[place] || 0
    const suggested = base + (capitals * 2) + dragons + castles

    const suggestedEl = row.querySelector("[data-points-calculator-target='suggested']")
    if (suggestedEl) {
      suggestedEl.textContent = place > 0 ? suggested : "—"
    }
  }
}
