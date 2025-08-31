import { Controller } from "@hotwired/stimulus"

// Registration controller for enhanced UX
export default class extends Controller {
  static targets = ["passwordConfirmation", "submitButton"]
  
  connect() {
    this.validateOnLoad()
  }
  
  validateOnLoad() {
    // Check if we have any server-side errors to display
    const errors = document.querySelectorAll('.field_with_errors')
    if (errors.length > 0) {
      errors.forEach(errorField => {
        const input = errorField.querySelector('input')
        if (input) {
          input.classList.add('error')
        }
      })
    }
  }
  
  validatePasswordMatch(event) {
    const confirmationField = event.target
    const passwordField = document.querySelector('input[name="user[password]"]')
    
    if (!passwordField || !confirmationField.value) return
    
    const errorElement = document.getElementById('password-confirmation-error')
    
    if (confirmationField.value !== passwordField.value) {
      confirmationField.classList.add('error')
      confirmationField.classList.remove('success')
      if (errorElement) {
        errorElement.textContent = 'Passwords do not match'
        errorElement.hidden = false
      }
    } else {
      confirmationField.classList.remove('error')
      confirmationField.classList.add('success')
      if (errorElement) {
        errorElement.hidden = true
      }
    }
  }
  
  handleValidForm(event) {
    // Form is valid, show loading state
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.innerHTML = '<span class="calm-spinner"></span> Creating your account...'
    }
    
    // Show success toast
    this.showToast('Creating your account...', 'info')
  }
  
  showToast(message, type = 'info') {
    // Reuse the toast functionality from unified_auth_controller
    const toast = document.createElement('div')
    toast.className = `calm-toast calm-toast-${type} animate-fade-in`
    toast.innerHTML = `
      <span class="calm-toast-icon">${this.getToastIcon(type)}</span>
      <span class="calm-toast-message">${message}</span>
    `
    
    let container = document.querySelector('.calm-toast-container')
    if (!container) {
      container = document.createElement('div')
      container.className = 'calm-toast-container'
      document.body.appendChild(container)
    }
    
    container.appendChild(toast)
    
    setTimeout(() => {
      toast.style.opacity = '0'
      setTimeout(() => toast.remove(), 300)
    }, 4000)
  }
  
  getToastIcon(type) {
    const icons = {
      success: '✓',
      error: '✕',
      info: 'ℹ',
      warning: '!'
    }
    return icons[type] || icons.info
  }
}