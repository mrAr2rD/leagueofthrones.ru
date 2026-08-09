import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "machine", "window", "track", "status"]
  static values = {
    cards: Array,
    duration: { type: Number, default: 5000 }
  }

  async spin(event) {
    if (this.committing) return

    event.preventDefault()
    if (this.spinning) return

    const form = event.currentTarget
    const confirmation = form.dataset.tidesReelConfirmMessage
    if (confirmation && !window.confirm(confirmation)) return

    this.spinning = true
    this.element.classList.add("is-spinning")
    this.element.setAttribute("aria-busy", "true")
    this.overlayTarget.setAttribute("aria-hidden", "false")
    this.element.querySelectorAll("button").forEach((button) => { button.disabled = true })
    this.statusTarget.textContent = "Судьба выбирает сторону…"

    try {
      const result = await this.drawCard(form)
      await this.animateTo(result.card)

      this.committing = true
      this.statusTarget.textContent = `Перевес: +${result.card.strength} · ${result.card.label}`
      this.machineTarget.classList.add("has-stopped")
      this.previewTimer = window.setTimeout(() => this.openPreview(result.preview_url), 650)
    } catch (_error) {
      this.statusTarget.textContent = "Судьба молчит. Попробуйте снова"
      this.machineTarget.classList.add("has-error")
      this.resetTimer = window.setTimeout(() => this.reset(), 1400)
    }
  }

  async drawCard(form) {
    const response = await fetch(form.action, {
      method: form.method,
      body: new FormData(form),
      credentials: "same-origin",
      headers: {
        Accept: "application/json",
        "X-Requested-With": "XMLHttpRequest"
      }
    })

    if (!response.ok) throw new Error(`Spin failed with status ${response.status}`)

    return response.json()
  }

  async animateTo(resultCard) {
    const target = this.buildSequence(resultCard)
    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    const duration = reducedMotion ? 450 : this.durationValue

    await this.nextFrame()

    const viewportWidth = this.windowTarget.clientWidth
    const targetCenter = target.offsetLeft + (target.offsetWidth / 2)
    const finalPosition = Math.round((viewportWidth / 2) - targetCenter)

    this.statusTarget.textContent = "Ветра войны набирают силу…"
    this.slowdownTimer = window.setTimeout(() => {
      this.statusTarget.textContent = "Чаша весов склоняется…"
    }, duration * 0.52)
    this.approachTimer = window.setTimeout(() => {
      this.statusTarget.textContent = "Исход сражения близок…"
      this.machineTarget.classList.add("is-approaching")
    }, duration * 0.76)

    const motionStops = [
      [0, 0],
      [0.04, 0.12],
      [0.1, 0.27],
      [0.18, 0.42],
      [0.28, 0.56],
      [0.4, 0.68],
      [0.52, 0.78],
      [0.64, 0.86],
      [0.75, 0.92],
      [0.84, 0.96],
      [0.92, 0.985],
      [0.97, 0.997],
      [1, 1]
    ]
    const keyframes = motionStops.map(([offset, progress]) => ({
      transform: `translate3d(${Math.round(finalPosition * progress)}px, 0, 0)`,
      offset
    }))

    this.animation = this.trackTarget.animate(keyframes, {
      duration,
      easing: "linear",
      fill: "forwards"
    })

    await this.animation.finished
  }

  buildSequence(resultCard) {
    const targetIndex = 42
    const sequenceLength = 49
    const cards = Array.from({ length: sequenceLength }, () => this.randomCard())
    cards[targetIndex] = resultCard

    this.trackTarget.replaceChildren(...cards.map((card, index) => {
      return this.buildCard(card, index === targetIndex)
    }))

    return this.trackTarget.children[targetIndex]
  }

  buildCard(card, winning) {
    const element = document.createElement("span")
    const variant = card.symbol || "plain"
    element.className = `tides-beta-case-card tides-beta-case-card-${variant}`
    element.dataset.cardKey = card.key
    if (winning) element.classList.add("is-winning")

    const strength = document.createElement("b")
    strength.textContent = `+${card.strength}`

    const symbol = document.createElement("i")
    symbol.className = card.symbol ? `tides-card-symbol-${card.symbol}` : "tides-beta-case-plain"
    symbol.setAttribute("aria-hidden", "true")

    const label = document.createElement("small")
    label.textContent = card.label

    element.append(strength, symbol, label)
    return element
  }

  randomCard() {
    return this.cardsValue[Math.floor(Math.random() * this.cardsValue.length)]
  }

  nextFrame() {
    return new Promise((resolve) => {
      window.requestAnimationFrame(() => window.requestAnimationFrame(resolve))
    })
  }

  openPreview(url) {
    const frame = this.element.closest("turbo-frame")
    if (frame) {
      frame.src = url
    } else {
      window.location.assign(url)
    }
  }

  reset() {
    this.spinning = false
    this.element.classList.remove("is-spinning")
    this.element.removeAttribute("aria-busy")
    this.overlayTarget.setAttribute("aria-hidden", "true")
    this.machineTarget.classList.remove("has-error")
    this.machineTarget.classList.remove("is-approaching")
    this.element.querySelectorAll("button").forEach((button) => { button.disabled = false })
  }

  disconnect() {
    this.animation?.cancel()
    window.clearTimeout(this.previewTimer)
    window.clearTimeout(this.resetTimer)
    window.clearTimeout(this.slowdownTimer)
    window.clearTimeout(this.approachTimer)
  }
}
