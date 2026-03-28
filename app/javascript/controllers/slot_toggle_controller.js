import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "playerSelect", "houseSelect", "houseHint"]
  static values = {
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
  }

  syncRow(row) {
    const playerSelect = row.querySelector("[data-slot-toggle-target='playerSelect']")
    const houseSelect = row.querySelector("[data-slot-toggle-target='houseSelect']")
    const houseHint = row.querySelector("[data-slot-toggle-target='houseHint']")

    if (!playerSelect || !houseSelect) return

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
        blankLabel: "— свободных домов нет —",
        disabled: true
      })

      if (houseHint) {
        houseHint.textContent = "У этого игрока не осталось свободных домов"
      }

      return
    }

    const nextValue = availableOptions.some(([, houseKey]) => houseKey === selectedHouse) ? selectedHouse : availableOptions[0][1]

    this.populateHouseSelect(houseSelect, availableOptions, nextValue, {
      includeBlank: false,
      disabled: false
    })

    if (houseHint) {
      houseHint.textContent = `Можно выбрать: ${availableOptions.map(([label]) => label).join(", ")}`
    }
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

    if (!includeBlank && !select.value && options.length > 0) {
      select.value = options[0][1]
    }
  }

  findHouseOption(houseKey) {
    return this.allHouseOptionsValue.find(([, key]) => key === houseKey) || [houseKey, houseKey]
  }
}
