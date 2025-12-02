import { Controller } from "@hotwired/stimulus"

// Controller générique pour filtrer une liste d'items avec recherche
// Usage: data-controller="search-filter" data-search-filter-key-value="city"
export default class extends Controller {
  static targets = ["list", "badges"]
  static values = {
    key: String  // Le data-attribute à filtrer (ex: "city", "practice", "teacher", "country")
  }

  connect() {
    console.log('🔌 search-filter connected, key:', this.keyValue)
    this.updateBadges()
  }

  filter(event) {
    const search = event.target.value.toLowerCase()
    console.log('🔍 Filtering with:', search, 'key:', this.keyValue)
    const items = this.listTarget.querySelectorAll('label')
    console.log('📋 Found items:', items.length)

    items.forEach(item => {
      const value = item.dataset[this.keyValue]
      if (value && value.includes(search)) {
        item.classList.remove('hidden')
      } else {
        item.classList.add('hidden')
      }
    })
  }

  updateBadges() {
    if (!this.hasBadgesTarget) return

    const checkboxes = this.listTarget.querySelectorAll('input[type="checkbox"]:checked')
    const badgesContainer = this.badgesTarget

    if (checkboxes.length === 0) {
      badgesContainer.innerHTML = '<p class="text-sm text-base-content/50">Aucune sélection</p>'
    } else {
      const badges = Array.from(checkboxes).map(checkbox => {
        const label = checkbox.closest('label').querySelector('.label-text').textContent
        return `<span class="badge badge-info">${label}</span>`
      }).join('')

      badgesContainer.innerHTML = `
        <p class="text-sm font-medium mb-2">Sélection :</p>
        <div class="flex flex-wrap gap-2">${badges}</div>
      `
    }
  }
}
