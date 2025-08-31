import { Controller } from "@hotwired/stimulus"

// Mobile menu controller for responsive navigation
export default class extends Controller {
  static targets = ["menu", "toggleButton", "toggleIcon"]
  
  connect() {
    // Close menu when clicking outside
    document.addEventListener('click', this.handleClickOutside.bind(this))
    
    // Close menu on Turbo navigation
    document.addEventListener('turbo:before-visit', this.close.bind(this))
  }
  
  disconnect() {
    document.removeEventListener('click', this.handleClickOutside.bind(this))
    document.removeEventListener('turbo:before-visit', this.close.bind(this))
  }
  
  toggle() {
    if (this.menuTarget.classList.contains('active')) {
      this.close()
    } else {
      this.open()
    }
  }
  
  open() {
    this.menuTarget.classList.add('active')
    this.toggleButtonTarget.setAttribute('aria-expanded', 'true')
    this.animateIcon(true)
  }
  
  close() {
    this.menuTarget.classList.remove('active')
    this.toggleButtonTarget.setAttribute('aria-expanded', 'false')
    this.animateIcon(false)
  }
  
  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }
  
  animateIcon(isOpen) {
    const spans = this.toggleButtonTarget.querySelectorAll('span')
    if (isOpen) {
      spans[0].style.transform = 'rotate(45deg) translate(5px, 5px)'
      spans[1].style.opacity = '0'
      spans[2].style.transform = 'rotate(-45deg) translate(5px, -5px)'
    } else {
      spans[0].style.transform = ''
      spans[1].style.opacity = '1'
      spans[2].style.transform = ''
    }
  }
}