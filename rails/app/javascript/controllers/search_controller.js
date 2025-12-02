import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "clear"]

  connect() {
    this.timeout = null
    
    // Si l'input a une valeur (après recherche), remettre le focus
    if (this.inputTarget.value.trim() !== "") {
      // Petit délai pour s'assurer que le DOM est bien chargé
      setTimeout(() => {
        this.inputTarget.focus()
        // Mettre le curseur à la fin du texte
        const length = this.inputTarget.value.length
        this.inputTarget.setSelectionRange(length, length)
      }, 100)
      
      // Afficher le bouton clear si on a une valeur
      if (this.hasClearTarget) {
        this.clearTarget.classList.remove("hidden")
      }
    }
  }

  // Recherche en temps réel avec debounce
  search() {
    clearTimeout(this.timeout)
    
    const query = this.inputTarget.value.trim()
    
    // Afficher/masquer le bouton clear
    if (this.hasClearTarget) {
      if (query.length > 0) {
        this.clearTarget.classList.remove("hidden")
      } else {
        this.clearTarget.classList.add("hidden")
      }
    }
    
    // Debounce de 1000ms (1 seconde) pour laisser le temps de taper
    this.timeout = setTimeout(() => {
      this.submitSearch()
    }, 1000)
  }

  // Clear la recherche
  clear(event) {
    event.preventDefault()
    this.inputTarget.value = ""
    if (this.hasClearTarget) {
      this.clearTarget.classList.add("hidden")
    }
    this.inputTarget.focus()
    this.submitSearch()
  }

  // Soumettre le formulaire
  submitSearch() {
    const form = this.element.querySelector("form")
    if (form) {
      form.requestSubmit()
    }
  }

  // Gérer la touche Escape pour clear
  handleKeydown(event) {
    if (event.key === "Escape") {
      if (this.inputTarget.value.trim() !== "") {
        this.clear(event)
      }
    }
  }
}
