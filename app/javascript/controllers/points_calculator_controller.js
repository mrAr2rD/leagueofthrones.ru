import { Controller } from "@hotwired/stimulus"

const PLACE_POINTS = { 1: 12, 2: 7, 3: 6, 4: 5, 5: 4, 6: 3, 7: 2, 8: 1 }
const MAX_CAPITAL_POINTS = 3
const MAX_CASTLES_POINTS = 5
const TABLE_A_BONUS_PLACES = new Set([1, 2, 3])

export default class extends Controller {
  static targets = ["row"]
  static values = { tableLetter: String }

  connect() {
    this.rowTargets.forEach((row) => {
      this.syncAdjustmentFromInput(row)
      this.calculateRow(row)
    })
  }

  calculate(event) {
    const row = event.target.closest("[data-points-calculator-target='row']")
    if (!row) return

    this.calculateRow(row)
  }

  updateManualAdjustment(event) {
    const row = event.target.closest("[data-points-calculator-target='row']")
    if (!row) return

    this.syncAdjustmentFromInput(row)
  }

  calculateRow(row) {
    const suggested = this.suggestedPointsFor(row)
    const suggestedEl = row.querySelector("[data-points-calculator-target='suggested']")
    const pointsEl = row.querySelector("[data-points-calculator-target='points']")

    if (suggested === null) {
      if (suggestedEl) suggestedEl.textContent = "—"
      if (pointsEl) pointsEl.value = ""
      row.dataset.pointsAdjustment = "0"
      return
    }

    if (suggestedEl) {
      suggestedEl.textContent = suggested
    }

    if (pointsEl) {
      pointsEl.value = suggested + this.manualAdjustmentFor(row)
    }
  }

  syncAdjustmentFromInput(row) {
    const pointsEl = row.querySelector("[data-points-calculator-target='points']")
    if (!pointsEl) return

    const suggested = this.suggestedPointsFor(row)
    const currentPoints = this.integerValue(pointsEl.value)

    row.dataset.pointsAdjustment =
      suggested === null || currentPoints === null ? "0" : String(currentPoints - suggested)
  }

  suggestedPointsFor(row) {
    const place = parseInt(row.querySelector("[data-points-calculator-target='place']")?.value) || 0
    if (place <= 0) return null

    const capitals = parseInt(row.querySelector("[data-points-calculator-target='capitals']")?.value) || 0
    const dragons = parseInt(row.querySelector("[data-points-calculator-target='dragons']")?.value) || 0
    const castles = parseInt(row.querySelector("[data-points-calculator-target='castles']")?.value) || 0

    const base = PLACE_POINTS[place] || 0
    const tableBonus = this.tableLetterValue === "A" && TABLE_A_BONUS_PLACES.has(place) ? 1 : 0

    return base + tableBonus + Math.min(capitals, MAX_CAPITAL_POINTS) + dragons + Math.min(castles, MAX_CASTLES_POINTS)
  }

  manualAdjustmentFor(row) {
    return parseInt(row.dataset.pointsAdjustment || "0", 10) || 0
  }

  integerValue(rawValue) {
    if (rawValue === null || rawValue === undefined || rawValue === "") return null

    const parsed = parseInt(rawValue, 10)
    return Number.isNaN(parsed) ? null : parsed
  }
}
