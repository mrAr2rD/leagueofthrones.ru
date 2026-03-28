import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "playerSelect", "houseSelect", "houseHint", "formError"]
  static values = {
    allPlayerOptions: Array,
    blockedPlayerIds: Array,
    allHouseOptions: Array,
    playerHouseOptions: Object
  }

  connect() {
    this.refresh()
  }

  toggle() {
    this.refresh()
  }

  refresh() {
    this.rowTargets.forEach((row) => this.syncRow(row))

    if (this.incompleteRows().length === 0) {
      this.hideFormError()
    }
  }

  syncRow(row) {
    const playerSelect = row.querySelector("[data-slot-toggle-target='playerSelect']")
    const houseSelect = row.querySelector("[data-slot-toggle-target='houseSelect']")
    const houseHint = row.querySelector("[data-slot-toggle-target='houseHint']")

    if (!playerSelect || !houseSelect) return

    this.syncPlayerSelect(playerSelect)

    const empty = playerSelect.value === ""
    const selectedHouse = houseSelect.value

    row.classList.toggle("bg-gray-50", empty)
    row.classList.toggle("opacity-50", empty)

    if (empty) {
      this.populateHouseSelect(houseSelect, this.allHouseOptionsValue, "", {
        includeBlank: true,
        disabled: true
      })

      if (houseHint) {
        houseHint.textContent = "Сначала выберите игрока"
      }

      return
    }

    const playerOptions = this.playerHouseOptionsValue[playerSelect.value] || this.allHouseOptionsValue
    const takenHouses = new Set(
      this.houseSelectTargets
        .filter((select) => select !== houseSelect)
        .map((select) => select.value)
        .filter(Boolean)
    )

    let availableOptions = playerOptions.filter(([, houseKey]) => !takenHouses.has(houseKey) || houseKey === selectedHouse)

    if (selectedHouse && !availableOptions.some(([, houseKey]) => houseKey === selectedHouse)) {
      availableOptions = [this.findHouseOption(selectedHouse), ...availableOptions]
    }

    if (availableOptions.length === 0) {
      this.populateHouseSelect(houseSelect, [], "", {
        includeBlank: true,
        disabled: false
      })

      if (houseHint) {
        houseHint.textContent = "У этого игрока не осталось свободных домов"
      }

      return
    }

    const nextValue = availableOptions.some(([, houseKey]) => houseKey === selectedHouse) ? selectedHouse : ""

    this.populateHouseSelect(houseSelect, availableOptions, nextValue, {
      includeBlank: true,
      disabled: false
    })

    if (houseHint) {
      houseHint.textContent = `Можно выбрать: ${availableOptions.map(([label]) => label).join(", ")}`
    }
  }

  syncPlayerSelect(playerSelect) {
    const selectedPlayer = playerSelect.value
    const blockedPlayers = new Set(this.blockedPlayerIdsValue.map(String))
    const takenPlayers = new Set(
      this.playerSelectTargets
        .filter((select) => select !== playerSelect)
        .map((select) => select.value)
        .filter(Boolean)
    )
    const availableOptions = this.allPlayerOptionsValue.filter(([, playerId]) => {
      const playerKey = String(playerId)

      return (!blockedPlayers.has(playerKey) || playerKey === selectedPlayer) &&
        (!takenPlayers.has(playerKey) || playerKey === selectedPlayer)
    })

    this.populatePlayerSelect(playerSelect, availableOptions, selectedPlayer)
  }

  populatePlayerSelect(select, options, value) {
    select.innerHTML = ""

    const blankOption = document.createElement("option")
    blankOption.value = ""
    blankOption.textContent = "— свободный слот —"
    select.append(blankOption)

    options.forEach(([label, playerId]) => {
      const option = document.createElement("option")
      option.value = playerId
      option.textContent = label
      select.append(option)
    })

    select.value = value || ""
  }

  validateBeforeSubmit(event) {
    const incompleteRows = this.incompleteRows()
    if (incompleteRows.length === 0) {
      this.hideFormError()
      return
    }

    event.preventDefault()
    this.showFormError("Заполните игрока и дом в каждой занятой строке или очистите строку целиком.")

    const row = incompleteRows[0]
    const playerSelect = row.querySelector("[data-slot-toggle-target='playerSelect']")
    const houseSelect = row.querySelector("[data-slot-toggle-target='houseSelect']")
    const focusTarget = playerSelect?.value ? houseSelect : playerSelect
    focusTarget?.focus()
  }

  incompleteRows() {
    return this.rowTargets.filter((row) => {
      const playerSelect = row.querySelector("[data-slot-toggle-target='playerSelect']")
      const houseSelect = row.querySelector("[data-slot-toggle-target='houseSelect']")
      if (!playerSelect || !houseSelect) return false

      const playerFilled = playerSelect.value !== ""
      const houseFilled = houseSelect.value !== ""

      return playerFilled !== houseFilled
    })
  }

  populateHouseSelect(select, options, value, { includeBlank, blankLabel = "— дом —", disabled = false }) {
    select.innerHTML = ""

    if (includeBlank) {
      const blankOption = document.createElement("option")
      blankOption.value = ""
      blankOption.textContent = blankLabel
      select.append(blankOption)
    }

    options.forEach(([label, houseKey]) => {
      const option = document.createElement("option")
      option.value = houseKey
      option.textContent = label
      select.append(option)
    })

    select.disabled = disabled
    select.value = value || ""
  }

  findHouseOption(houseKey) {
    return this.allHouseOptionsValue.find(([, key]) => key === houseKey) || [houseKey, houseKey]
  }

  showFormError(message) {
    if (!this.hasFormErrorTarget) return

    this.formErrorTarget.textContent = message
    this.formErrorTarget.classList.remove("hidden")
  }

  hideFormError() {
    if (!this.hasFormErrorTarget) return

    this.formErrorTarget.textContent = ""
    this.formErrorTarget.classList.add("hidden")
  }
}
