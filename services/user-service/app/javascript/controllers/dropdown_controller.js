import { Controller } from "@hotwired/stimulus"

// Dropdown controller for peaceful, accessible dropdowns
export default class extends Controller {
  static targets = ["button", "menu"]
  
  connect() {
    this.open = false
    this.handleClickOutside = this.clickOutside.bind(this)
  }
  
  disconnect() {
    document.removeEventListener('click', this.handleClickOutside)
  }
  
  toggle(event) {
    event.stopPropagation()
    
    if (this.open) {
      this.close()
    } else {
      this.openMenu()
    }
  }
  
  openMenu() {
    this.menuTarget.classList.remove('hidden')
    this.buttonTarget.setAttribute('aria-expanded', 'true')
    this.open = true
    
    // Ensure menu is visible before animating
    requestAnimationFrame(() => {
      this.menuTarget.style.opacity = '1'
      this.menuTarget.style.transform = 'translateY(0)'
    })
    
    // Add click outside listener
    document.addEventListener('click', this.handleClickOutside)
    
    // Focus first menu item for accessibility
    const firstItem = this.menuTarget.querySelector('[role="menuitem"]')
    if (firstItem) {
      firstItem.focus()
    }
  }
  
  close() {
    this.menuTarget.style.opacity = '0'
    this.menuTarget.style.transform = 'translateY(-10px)'
    
    setTimeout(() => {
      this.menuTarget.classList.add('hidden')
    }, 200)
    
    this.buttonTarget.setAttribute('aria-expanded', 'false')
    this.open = false
    
    // Remove click outside listener
    document.removeEventListener('click', this.handleClickOutside)
  }
  
  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }
  
  // Keyboard navigation
  handleKeydown(event) {
    if (!this.open) return
    
    const items = Array.from(this.menuTarget.querySelectorAll('[role="menuitem"]'))
    const currentIndex = items.indexOf(document.activeElement)
    
    switch(event.key) {
      case 'Escape':
        this.close()
        this.buttonTarget.focus()
        break
      case 'ArrowDown':
        event.preventDefault()
        const nextIndex = currentIndex + 1 < items.length ? currentIndex + 1 : 0
        items[nextIndex].focus()
        break
      case 'ArrowUp':
        event.preventDefault()
        const prevIndex = currentIndex - 1 >= 0 ? currentIndex - 1 : items.length - 1
        items[prevIndex].focus()
        break
      case 'Home':
        event.preventDefault()
        items[0].focus()
        break
      case 'End':
        event.preventDefault()
        items[items.length - 1].focus()
        break
    }
  }
}