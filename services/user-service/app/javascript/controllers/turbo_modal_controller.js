import { Controller } from "@hotwired/stimulus"

// Modal controller optimized for Turbo
export default class extends Controller {
  static targets = ["modal", "backdrop", "content"]
  static values = {
    open: Boolean,
    closable: { type: Boolean, default: true }
  }
  
  connect() {
    // Handle Turbo frame loading inside modal
    if (this.hasContentTarget) {
      this.contentTarget.addEventListener('turbo:frame-load', () => {
        this.handleFrameLoad()
      })
    }
    
    // Close modal on navigation
    document.addEventListener('turbo:before-visit', () => {
      if (this.openValue) {
        this.close()
      }
    })
  }
  
  open(event) {
    event?.preventDefault()
    
    this.openValue = true
    document.body.style.overflow = 'hidden'
    
    // Animate in
    requestAnimationFrame(() => {
      this.element.classList.add('active')
      this.modalTarget.classList.add('active')
    })
    
    // Trap focus
    this.trapFocus()
    
    // Dispatch custom event
    this.dispatch('opened')
  }
  
  close(event) {
    if (event && !this.closableValue) {
      return
    }
    
    event?.preventDefault()
    
    this.openValue = false
    document.body.style.overflow = ''
    
    // Animate out
    this.element.classList.remove('active')
    this.modalTarget.classList.remove('active')
    
    // Release focus trap
    this.releaseFocus()
    
    // Clear Turbo frame content after animation
    setTimeout(() => {
      if (this.hasContentTarget) {
        const turboFrame = this.contentTarget.querySelector('turbo-frame')
        if (turboFrame) {
          turboFrame.src = ''
        }
      }
    }, 300)
    
    // Dispatch custom event
    this.dispatch('closed')
  }
  
  closeOnBackdrop(event) {
    if (event.target === event.currentTarget && this.closableValue) {
      this.close()
    }
  }
  
  closeOnEscape(event) {
    if (event.key === 'Escape' && this.openValue && this.closableValue) {
      this.close()
    }
  }
  
  handleFrameLoad() {
    // Auto-resize modal based on content
    const content = this.contentTarget
    const frame = content.querySelector('turbo-frame')
    
    if (frame) {
      // Remove loading state
      frame.classList.remove('turbo-frame-loading')
      
      // Check for form in frame
      const form = frame.querySelector('form')
      if (form) {
        this.setupFormHandling(form)
      }
    }
  }
  
  setupFormHandling(form) {
    // Handle successful form submission
    form.addEventListener('turbo:submit-end', (event) => {
      if (event.detail.success) {
        // Check if we should close modal
        const shouldClose = form.dataset.modalClose !== 'false'
        if (shouldClose) {
          this.close()
        }
      }
    })
  }
  
  trapFocus() {
    this.previousActiveElement = document.activeElement
    
    const focusableElements = this.modalTarget.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    )
    
    this.firstFocusable = focusableElements[0]
    this.lastFocusable = focusableElements[focusableElements.length - 1]
    
    // Focus first element
    this.firstFocusable?.focus()
    
    // Add tab trap listener
    this.handleTab = this.handleTabKey.bind(this)
    document.addEventListener('keydown', this.handleTab)
  }
  
  releaseFocus() {
    document.removeEventListener('keydown', this.handleTab)
    this.previousActiveElement?.focus()
  }
  
  handleTabKey(event) {
    if (event.key !== 'Tab') return
    
    if (event.shiftKey) {
      if (document.activeElement === this.firstFocusable) {
        event.preventDefault()
        this.lastFocusable?.focus()
      }
    } else {
      if (document.activeElement === this.lastFocusable) {
        event.preventDefault()
        this.firstFocusable?.focus()
      }
    }
  }
}