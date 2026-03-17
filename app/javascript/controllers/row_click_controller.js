import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open(event) {
    const url = event.currentTarget.dataset.rowClickUrlParam
    if (!url) return
    window.location.href = url
  }
}
