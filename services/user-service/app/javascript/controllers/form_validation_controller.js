import { Controller } from "@hotwired/stimulus"

// Form validation controller with Turbo integration
export default class extends Controller {
  static targets = ["form", "submit", "field", "error"]
  static values = { 
    realtime: Boolean,
    submitOnValid: Boolean 
  }
  
  connect() {
    this.validateOnConnect()
    
    if (this.realtimeValue) {
      this.setupRealtimeValidation()
    }
  }
  
  validateOnConnect() {
    if (this.hasFieldTarget) {
      this.fieldTargets.forEach(field => {
        if (field.value) {
          this.validateField(field)
        }
      })
    }
  }
  
  setupRealtimeValidation() {
    this.fieldTargets.forEach(field => {
      field.addEventListener('blur', () => this.validateField(field))
      field.addEventListener('input', () => {
        this.clearError(field)
        if (field.value) {
          this.debounce(() => this.validateField(field), 500)()
        }
      })
    })
  }
  
  validateField(field) {
    const validators = {
      required: (value) => value.trim() !== '',
      email: (value) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value),
      phone: (value) => /^[6-9]\d{9}$/.test(value),
      minLength: (value, length) => value.length >= parseInt(length),
      maxLength: (value, length) => value.length <= parseInt(length),
      pattern: (value, pattern) => new RegExp(pattern).test(value)
    }
    
    let isValid = true
    const value = field.value
    
    // Check each validation attribute
    Object.keys(validators).forEach(validator => {
      const attr = field.getAttribute(`data-${validator}`)
      if (attr !== null) {
        const validatorFunc = validators[validator]
        const param = attr || true
        
        if (!validatorFunc(value, param)) {
          isValid = false
          const message = field.getAttribute(`data-${validator}-message`) || 
                         this.getDefaultMessage(validator, param)
          this.showError(field, message)
        }
      }
    })
    
    if (isValid) {
      this.showSuccess(field)
    }
    
    this.updateSubmitButton()
    return isValid
  }
  
  validateForm(event) {
    event.preventDefault()
    
    let isValid = true
    this.fieldTargets.forEach(field => {
      if (!this.validateField(field)) {
        isValid = false
      }
    })
    
    if (isValid) {
      if (this.submitOnValidValue) {
        this.formTarget.submit()
      } else {
        // Dispatch custom event for Turbo handling
        const validEvent = new CustomEvent('form:valid', {
          detail: { form: this.formTarget }
        })
        this.element.dispatchEvent(validEvent)
      }
    } else {
      // Focus first error field
      const firstError = this.element.querySelector('.calm-form-error:not([hidden])')
      if (firstError) {
        const field = firstError.previousElementSibling
        if (field) field.focus()
      }
    }
  }
  
  showError(field, message) {
    const errorEl = this.getErrorElement(field)
    if (errorEl) {
      errorEl.textContent = message
      errorEl.hidden = false
      field.classList.add('error')
      field.classList.remove('success')
    }
  }
  
  showSuccess(field) {
    const errorEl = this.getErrorElement(field)
    if (errorEl) {
      errorEl.hidden = true
      field.classList.remove('error')
      field.classList.add('success')
    }
  }
  
  clearError(field) {
    const errorEl = this.getErrorElement(field)
    if (errorEl) {
      errorEl.hidden = true
      field.classList.remove('error', 'success')
    }
  }
  
  getErrorElement(field) {
    // Look for error element with matching ID
    const errorId = field.getAttribute('aria-describedby')
    if (errorId) {
      return document.getElementById(errorId)
    }
    
    // Look for next sibling with error class
    const nextEl = field.nextElementSibling
    if (nextEl && nextEl.classList.contains('calm-form-error')) {
      return nextEl
    }
    
    return null
  }
  
  getDefaultMessage(validator, param) {
    const messages = {
      required: 'This field is required',
      email: 'Please enter a valid email address',
      phone: 'Please enter a valid 10-digit phone number',
      minLength: `Must be at least ${param} characters`,
      maxLength: `Must be no more than ${param} characters`,
      pattern: 'Please match the required format'
    }
    
    return messages[validator] || 'Invalid input'
  }
  
  updateSubmitButton() {
    if (this.hasSubmitTarget) {
      const hasErrors = this.element.querySelectorAll('.error').length > 0
      this.submitTarget.disabled = hasErrors
    }
  }
  
  debounce(func, wait) {
    let timeout
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout)
        func(...args)
      }
      clearTimeout(timeout)
      timeout = setTimeout(later, wait)
    }
  }
}