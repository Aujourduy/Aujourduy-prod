import { Controller } from "@hotwired/stimulus"

// Contrôleur du formulaire d'événement
export default class extends Controller {
  static targets = [
    "singleSection", "recurrenceSection", "preview", "previewContent", "intervalLabel",
    "venueSelect", "onlineUrlField"
  ]

  connect() {
    const hidden = this.element.querySelector('#event_is_recurring')
    const val = hidden ? hidden.value : '0'
    const initialRecurring = (val === '1' || val === 'true')
    this.currentType = initialRecurring ? 'recurring' : 'single'

    // Appliquer l'état au chargement
    this._applyState(this.currentType)
    
    // Initialiser l'état du champ online_url
    this._initOnlineUrlField()

    // Garde avant submit
    this._beforeSubmit = () => {
      const isRecurring = (this.currentType === 'recurring')
      this._toggleRequired(isRecurring)
      this._toggleDisabled(isRecurring)
    }
    this.element.addEventListener('submit', this._beforeSubmit)
  }

  disconnect() {
    if (this._beforeSubmit) this.element.removeEventListener('submit', this._beforeSubmit)
  }

  selectCard(event) {
    event.preventDefault()
    const targetType = event.currentTarget.dataset.type
    if (this.currentType === targetType) return
    this.currentType = targetType
    this._applyState(targetType)
  }

  toggleOnlineUrl(event) {
    const isChecked = event.target.checked
    if (this.hasOnlineUrlFieldTarget) {
      if (isChecked) {
        this.onlineUrlFieldTarget.classList.remove('hidden')
        const input = this.onlineUrlFieldTarget.querySelector('input')
        if (input) input.required = true
      } else {
        this.onlineUrlFieldTarget.classList.add('hidden')
        const input = this.onlineUrlFieldTarget.querySelector('input')
        if (input) {
          input.required = false
          input.value = ''
        }
      }
    }
  }

  _initOnlineUrlField() {
    const checkbox = this.element.querySelector('#event_is_online')
    if (checkbox && this.hasOnlineUrlFieldTarget) {
      if (checkbox.checked) {
        this.onlineUrlFieldTarget.classList.remove('hidden')
        const input = this.onlineUrlFieldTarget.querySelector('input')
        if (input) input.required = true
      } else {
        this.onlineUrlFieldTarget.classList.add('hidden')
        const input = this.onlineUrlFieldTarget.querySelector('input')
        if (input) input.required = false
      }
    }
  }

  _applyState(type) {
    const isRecurring = (type === 'recurring')
    const hiddenField = this.element.querySelector('#event_is_recurring')

    // Visuel
    if (isRecurring) {
      this._activateCard(document.getElementById('card-recurring'), document.getElementById('card-recurring')?.querySelector('.badge'))
      this._deactivateCard(document.getElementById('card-single'), document.getElementById('card-single')?.querySelector('.badge'))
    } else {
      this._activateCard(document.getElementById('card-single'), document.getElementById('card-single')?.querySelector('.badge'))
      this._deactivateCard(document.getElementById('card-recurring'), document.getElementById('card-recurring')?.querySelector('.badge'))
    }

    if (hiddenField) hiddenField.value = isRecurring ? '1' : '0'

    // Affichage
    if (isRecurring) {
      this.singleSectionTarget.classList.add("hidden")
      this.recurrenceSectionTarget.classList.remove("hidden")
    } else {
      this.singleSectionTarget.classList.remove("hidden")
      this.recurrenceSectionTarget.classList.add("hidden")
    }

    // Gestion logique
    this._toggleRequired(isRecurring)
    this._toggleDisabled(isRecurring)
  }

  _toggleRequired(isRecurring) {
    const uniqueFields = this.singleSectionTarget.querySelectorAll("input, select, textarea")
    const recurringFields = this.recurrenceSectionTarget.querySelectorAll("input, select, textarea")

    uniqueFields.forEach(f => f.required = !isRecurring)
    recurringFields.forEach(f => f.required = isRecurring)
  }

  _toggleDisabled(isRecurring) {
    const uniqueFields = this.singleSectionTarget.querySelectorAll("input, select, textarea")
    const recurringFields = this.recurrenceSectionTarget.querySelectorAll("input, select, textarea")

    uniqueFields.forEach(f => f.disabled = isRecurring)
    recurringFields.forEach(f => f.disabled = !isRecurring)
  }

  _activateCard(card, badge) {
    if (!card || !badge) return
    card.classList.add("selected", "border-primary")
    card.classList.remove("border-base-300")
    badge.classList.remove("badge-ghost", "hidden")
    badge.classList.add("badge-primary")
  }

  _deactivateCard(card, badge) {
    if (!card || !badge) return
    card.classList.remove("selected", "border-primary")
    card.classList.add("border-base-300")
    badge.classList.remove("badge-primary")
    badge.classList.add("badge-ghost", "hidden")
  }

  onVenueSelect(event) {
    if (event.target.value === 'new') {
      window.location.href = '/venues/new'
    }
  }

  updateFrequencyOptions(event) {
    const frequency = event.target.value
    const labels = { 'daily': 'jour(s)', 'weekly': 'semaine(s)', 'monthly': 'mois' }
    if (this.hasIntervalLabelTarget) {
      this.intervalLabelTarget.textContent = labels[frequency] || 'unité(s)'
    }
  }

  async previewRecurrence() {
    const formData = new FormData(this.element)
    try {
      const response = await fetch('/events/preview_recurrence', {
        method: 'POST',
        body: formData,
        headers: { 'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content }
      })
      const data = await response.json()
      if (data.success) this.displayPreview(data.preview)
      else this.showError(data.error)
    } catch {
      this.showError("Erreur lors de la prévisualisation")
    }
  }

  displayPreview(preview) {
    if (!this.hasPreviewContentTarget) return

    const total = preview.occurrences?.length || 0
    let html = `<p class="font-semibold mb-2">Environ ${total} occurrence${total > 1 ? 's' : ''} seront créées</p>`

    if (preview.occurrences.length > 0) {
      html += '<ul class="list-disc list-inside space-y-1 text-sm">'
      preview.occurrences.forEach(o => {
        html += `<li>${o.formatted_date} de ${o.start_time} à ${o.end_time}</li>`
      })
      html += '</ul>'
      if (preview.truncated) html += '<p class="text-xs opacity-70 mt-2">... et plus encore</p>'
    } else {
      html += '<p class="text-warning">Aucune occurrence n\'a été trouvée avec ces paramètres.</p>'
    }

    this.previewContentTarget.innerHTML = html
    this.previewTarget.classList.remove("hidden")
  }

  showError(message) {
    if (!this.hasPreviewContentTarget) return
    this.previewContentTarget.innerHTML = `<p class="text-error">${message}</p>`
    this.previewTarget.classList.remove("hidden")
  }
}
