import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "row",
    "playerSelect",
    "playerCombobox",
    "playerInput",
    "playerMenu",
    "playerWarning",
    "houseSelect",
    "houseHint",
    "formError"
  ]
  static values = {
    allPlayerOptions: Array,
    playerTourTableWarnings: Object,
    allHouseOptions: Array,
    playerHouseOptions: Object,
    houseReuseAllowed: Boolean,
    playerHistoricalHouses: Object
  }

  connect() {
    this.handleDocumentClick = this.handleDocumentClick.bind(this)
    document.addEventListener("click", this.handleDocumentClick)
    this.refresh()
  }

  disconnect() {
    document.removeEventListener("click", this.handleDocumentClick)
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
    this.syncPlayerCombobox(row)
    this.syncPlayerWarning(row)

    const empty = playerSelect.value === ""
    const selectedHouse = houseSelect.value

    row.classList.toggle("bg-gray-50", empty)
    if (empty) {
      this.populateHouseSelect(houseSelect, this.allHouseOptionsValue, "", {
        includeBlank: true,
        disabled: true
      })

      if (houseHint) {
        this.setHouseHintAppearance(houseHint, false)
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

    const availableOptions = playerOptions.filter(([, houseKey]) => !takenHouses.has(houseKey) || houseKey === selectedHouse)

    if (availableOptions.length === 0) {
      this.populateHouseSelect(houseSelect, [], "", {
        includeBlank: true,
        disabled: false
      })

      if (houseHint) {
        this.setHouseHintAppearance(houseHint, false)
        houseHint.textContent = "У этого игрока не осталось свободных домов"
      }

      return
    }

    const nextValue = availableOptions.some(([, houseKey]) => houseKey === selectedHouse) ? selectedHouse : ""
    const historicalHouses = new Set(this.playerHistoricalHousesValue[playerSelect.value] || [])
    const displayOptions = availableOptions.map(([label, houseKey]) => [
      this.houseReuseAllowedValue && historicalHouses.has(houseKey) ? `${label} — уже играл` : label,
      houseKey
    ])

    this.populateHouseSelect(houseSelect, displayOptions, nextValue, {
      includeBlank: true,
      disabled: false
    })

    if (houseHint) {
      this.renderHouseHint(houseHint, historicalHouses, nextValue, availableOptions)
    }
  }

  renderHouseHint(houseHint, historicalHouses, selectedHouse, availableOptions) {
    const repeatedHouse = this.houseReuseAllowedValue && selectedHouse !== "" && historicalHouses.has(selectedHouse)

    this.setHouseHintAppearance(houseHint, repeatedHouse)

    if (repeatedHouse) {
      const houseLabel = this.allHouseOptionsValue.find(([, houseKey]) => houseKey === selectedHouse)?.[0] || selectedHouse
      houseHint.textContent = `Внимание: игрок уже играл за дом «${houseLabel}». В заключительном туре повтор разрешён.`
    } else if (this.houseReuseAllowedValue) {
      houseHint.textContent = "Заключительный тур: можно повторить дом; ранее использованные дома отмечены «уже играл»."
    } else {
      houseHint.textContent = `Можно выбрать: ${availableOptions.map(([label]) => label).join(", ")}`
    }
  }

  setHouseHintAppearance(houseHint, warning) {
    houseHint.classList.toggle("font-medium", warning)
    houseHint.classList.toggle("text-amber-700", warning)
    houseHint.classList.toggle("text-gray-500", !warning)
  }

  syncPlayerSelect(playerSelect) {
    const selectedPlayer = playerSelect.value
    const takenPlayers = new Set(
      this.playerSelectTargets
        .filter((select) => select !== playerSelect)
        .map((select) => select.value)
        .filter(Boolean)
    )
    const availableOptions = this.allPlayerOptionsValue.filter(([, playerId]) => {
      const playerKey = String(playerId)

      return !takenPlayers.has(playerKey) || playerKey === selectedPlayer
    })

    this.populatePlayerSelect(playerSelect, availableOptions, selectedPlayer)
  }

  syncPlayerCombobox(row) {
    const playerSelect = row.querySelector("[data-slot-toggle-target='playerSelect']")
    const playerInput = row.querySelector("[data-slot-toggle-target='playerInput']")
    const playerMenu = row.querySelector("[data-slot-toggle-target='playerMenu']")

    if (!playerSelect || !playerInput) return

    if (playerInput.dataset.searching !== "true") {
      playerInput.value = this.selectedPlayerLabel(playerSelect)
    }

    playerInput.dataset.selectedValue = playerSelect.value || ""

    if (playerMenu && !playerMenu.classList.contains("hidden")) {
      this.renderPlayerMenu(row)
    }
  }

  syncPlayerWarning(row) {
    const playerSelect = row.querySelector("[data-slot-toggle-target='playerSelect']")
    const playerWarning = row.querySelector("[data-slot-toggle-target='playerWarning']")

    if (!playerSelect || !playerWarning) return

    const tableLetters = this.playerTourTableWarningsValue[playerSelect.value] || []
    playerWarning.textContent = tableLetters.length > 0
      ? `Уже играет в этом туре: ${tableLetters.map((tableLetter) => `стол ${tableLetter}`).join(", ")}`
      : ""
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

  openPlayerMenu(event) {
    const row = this.rowFor(event.currentTarget)
    if (!row) return
    if (event.type === "click" && event.currentTarget.dataset.searching === "true") return

    this.closePlayerMenus(row)
    event.currentTarget.dataset.searching = "true"
    event.currentTarget.value = ""
    this.renderPlayerMenu(row, "")
  }

  filterPlayers(event) {
    const row = this.rowFor(event.currentTarget)
    if (!row) return

    event.currentTarget.dataset.searching = "true"
    this.renderPlayerMenu(row)
  }

  choosePlayer(event) {
    event.preventDefault()

    const row = this.rowFor(event.currentTarget)
    if (!row) return

    this.selectPlayer(row, event.currentTarget.dataset.playerId || "")
  }

  handlePlayerInputKeydown(event) {
    const row = this.rowFor(event.currentTarget)
    if (!row) return

    const playerMenu = row.querySelector("[data-slot-toggle-target='playerMenu']")

    if (event.key === "Escape") {
      this.closePlayerMenu(row, { resetInput: true })
      return
    }

    if (!playerMenu || playerMenu.classList.contains("hidden")) {
      if (event.key === "ArrowDown") {
        event.preventDefault()
        event.currentTarget.dataset.searching = "true"
        this.renderPlayerMenu(row)
      }
      return
    }

    const options = Array.from(playerMenu.querySelectorAll("[data-player-id]"))
    if (options.length === 0) return

    const currentIndex = Number(playerMenu.dataset.highlightedIndex || 0)

    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.highlightPlayerOption(playerMenu, Math.min(currentIndex + 1, options.length - 1))
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.highlightPlayerOption(playerMenu, Math.max(currentIndex - 1, 0))
    } else if (event.key === "Enter") {
      event.preventDefault()
      const selectedOption = options[Number(playerMenu.dataset.highlightedIndex || 0)]
      if (selectedOption) {
        this.selectPlayer(row, selectedOption.dataset.playerId || "")
      }
    }
  }

  renderPlayerMenu(row, queryOverride = null) {
    const playerSelect = row.querySelector("[data-slot-toggle-target='playerSelect']")
    const playerInput = row.querySelector("[data-slot-toggle-target='playerInput']")
    const playerMenu = row.querySelector("[data-slot-toggle-target='playerMenu']")

    if (!playerSelect || !playerInput || !playerMenu) return

    const query = this.normalize(queryOverride === null ? playerInput.value : queryOverride)
    const options = [
      ["— свободный слот —", ""],
      ...this.playerOptionsForSelect(playerSelect)
    ].filter(([label, playerId]) => {
      return playerId === "" || this.normalize(label).includes(query)
    })

    playerMenu.innerHTML = ""

    if (options.length === 0) {
      const empty = document.createElement("div")
      empty.className = "px-3 py-2 text-sm text-gray-500"
      empty.textContent = "Ничего не найдено"
      playerMenu.append(empty)
    } else {
      options.forEach(([label, playerId]) => {
        const option = document.createElement("button")
        option.type = "button"
        option.dataset.playerId = String(playerId)
        option.setAttribute("role", "option")
        option.setAttribute("aria-selected", String(String(playerId) === playerSelect.value))
        option.className = "block w-full px-3 py-2 text-left text-sm hover:bg-gray-50"
        option.textContent = label
        option.addEventListener("mousedown", (mouseEvent) => this.choosePlayer(mouseEvent))
        playerMenu.append(option)
      })

      this.highlightPlayerOption(playerMenu, 0)
    }

    playerInput.setAttribute("aria-expanded", "true")
    playerMenu.classList.remove("hidden")
  }

  selectPlayer(row, playerId) {
    const playerSelect = row.querySelector("[data-slot-toggle-target='playerSelect']")
    const playerInput = row.querySelector("[data-slot-toggle-target='playerInput']")
    if (!playerSelect || !playerInput) return

    playerSelect.value = playerId
    playerInput.dataset.searching = "false"
    playerInput.value = this.selectedPlayerLabel(playerSelect)
    this.closePlayerMenu(row)
    playerSelect.dispatchEvent(new Event("change", { bubbles: true }))
  }

  highlightPlayerOption(playerMenu, index) {
    const options = Array.from(playerMenu.querySelectorAll("[data-player-id]"))
    if (options.length === 0) return

    const nextIndex = Math.max(0, Math.min(index, options.length - 1))
    playerMenu.dataset.highlightedIndex = String(nextIndex)

    options.forEach((option, optionIndex) => {
      option.classList.toggle("bg-gray-100", optionIndex === nextIndex)
    })
  }

  closePlayerMenus(exceptRow = null) {
    this.rowTargets.forEach((row) => {
      if (exceptRow && row === exceptRow) return

      this.closePlayerMenu(row, { resetInput: true })
    })
  }

  closePlayerMenu(row, { resetInput = false } = {}) {
    const playerInput = row.querySelector("[data-slot-toggle-target='playerInput']")
    const playerMenu = row.querySelector("[data-slot-toggle-target='playerMenu']")

    if (playerInput) {
      playerInput.dataset.searching = "false"
      playerInput.setAttribute("aria-expanded", "false")

      if (resetInput) {
        const playerSelect = row.querySelector("[data-slot-toggle-target='playerSelect']")
        if (playerSelect) {
          playerInput.value = this.selectedPlayerLabel(playerSelect)
        }
      }
    }

    if (playerMenu) {
      playerMenu.classList.add("hidden")
      playerMenu.dataset.highlightedIndex = "0"
    }
  }

  handleDocumentClick(event) {
    if (event.target.closest("[data-slot-toggle-target='playerCombobox']")) return

    this.closePlayerMenus()
  }

  playerOptionsForSelect(select) {
    return Array.from(select.options)
      .filter((option) => option.value !== "")
      .map((option) => [option.textContent, option.value])
  }

  selectedPlayerLabel(select) {
    const selectedOption = Array.from(select.options).find((option) => option.value === select.value)

    return selectedOption?.textContent || ""
  }

  rowFor(element) {
    return element.closest("[data-slot-toggle-target='row']")
  }

  normalize(value) {
    return String(value || "").trim().toLowerCase()
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
    const playerInput = row.querySelector("[data-slot-toggle-target='playerInput']")
    const houseSelect = row.querySelector("[data-slot-toggle-target='houseSelect']")
    const focusTarget = playerSelect?.value ? houseSelect : playerInput || playerSelect
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
