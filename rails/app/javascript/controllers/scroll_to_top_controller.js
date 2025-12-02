import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.handleScroll = this.handleScroll.bind(this)
    window.addEventListener('scroll', this.handleScroll)
    this.handleScroll() // Vérifier l'état initial
  }

  disconnect() {
    window.removeEventListener('scroll', this.handleScroll)
  }

  handleScroll() {
    if (window.scrollY > 400) {
      this.element.classList.remove('hidden')
    } else {
      this.element.classList.add('hidden')
    }
  }

  scrollToTop() {
    window.scrollTo({
      top: 0,
      behavior: 'smooth'
    })
  }
}
