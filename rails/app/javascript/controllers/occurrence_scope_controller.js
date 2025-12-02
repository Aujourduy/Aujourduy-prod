import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submitButton"]
  
  connect() {
    console.log("Occurrence scope controller connected!")
  }
  
  // Intercepter la soumission AVANT que Turbo ne la traite
  submitForm(event) {
    // Vérifier si un radio est sélectionné
    const radios = this.element.querySelectorAll('input[name="event_occurrence[update_scope]"]')
    
    if (radios.length > 0) {
      const isSelected = Array.from(radios).some(radio => radio.checked)
      
      if (!isSelected) {
        event.preventDefault()
        event.stopPropagation()
        this.showError()
        return false
      }
    }
  }
  
  showError() {
    // Supprimer l'ancien message d'erreur s'il existe
    const oldAlert = document.querySelector('.scope-error-alert')
    if (oldAlert) oldAlert.remove()
    
    // Créer le message d'erreur
    const alert = document.createElement('div')
    alert.className = 'alert alert-error scope-error-alert mb-4'
    alert.innerHTML = `
      <div>
        <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <span><strong>⚠️ Veuillez sélectionner une option</strong> pour appliquer les modifications</span>
      </div>
    `
    
    // Insérer le message au début du formulaire
    this.element.prepend(alert)
    
    // Scroller vers le haut
    window.scrollTo({ top: 0, behavior: 'smooth' })
    
    // Supprimer après 5 secondes
    setTimeout(() => alert.remove(), 5000)
  }
  
  // Supprimer le message d'erreur quand un radio est sélectionné
  enableSubmit() {
    const alert = document.querySelector('.scope-error-alert')
    if (alert) alert.remove()
  }
}
