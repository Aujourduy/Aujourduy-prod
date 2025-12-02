import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.lastScroll = 0
    this.threshold = 100
    this.handleScroll = this.handleScroll.bind(this)
    window.addEventListener('scroll', this.handleScroll, { passive: true })
  }

  disconnect() {
    window.removeEventListener('scroll', this.handleScroll)
  }

  handleScroll() {
    const currentScroll = window.pageYOffset

    if (currentScroll <= 0) {
      this.element.classList.remove('hidden')
      return
    }

    if (currentScroll > this.lastScroll && currentScroll > this.threshold) {
      // Scroll vers le bas - masquer
      this.element.classList.add('hidden')
    } else {
      // Scroll vers le haut - afficher
      this.element.classList.remove('hidden')
    }

    this.lastScroll = currentScroll
  }
}
