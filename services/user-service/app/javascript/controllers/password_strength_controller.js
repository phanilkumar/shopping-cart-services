import { Controller } from "@hotwired/stimulus"

// Password strength checker for peaceful UX
export default class extends Controller {
  static targets = ["input", "fill", "level", "indicator", "text"]
  
  connect() {
    this.checkStrength()
  }
  
  checkStrength() {
    const password = this.inputTarget.value
    const strength = this.calculateStrength(password)
    
    this.updateDisplay(strength)
  }
  
  calculateStrength(password) {
    if (!password) return 0
    
    let strength = 0
    
    // Length check
    if (password.length >= 8) strength++
    if (password.length >= 12) strength++
    
    // Character variety checks
    if (/[a-z]/.test(password)) strength += 0.5  // lowercase
    if (/[A-Z]/.test(password)) strength += 0.5  // uppercase
    if (/[0-9]/.test(password)) strength += 0.5  // numbers
    if (/[^A-Za-z0-9]/.test(password)) strength += 0.5  // special chars
    
    // Penalize common patterns
    if (/(.)\1{2,}/.test(password)) strength -= 0.5  // repeated chars
    if (/^[0-9]+$/.test(password)) strength -= 0.5   // only numbers
    if (/^[a-zA-Z]+$/.test(password)) strength -= 0.5 // only letters
    
    // Common passwords check
    const commonPasswords = ['password', '12345678', 'qwerty', 'abc123', 'password123']
    if (commonPasswords.includes(password.toLowerCase())) {
      strength = 0
    }
    
    return Math.max(0, Math.min(4, Math.floor(strength)))
  }
  
  updateDisplay(strength) {
    const levels = [
      { text: 'Too weak', color: 'danger' },
      { text: 'Weak', color: 'danger' },
      { text: 'Fair', color: 'warning' },
      { text: 'Good', color: 'info' },
      { text: 'Strong', color: 'success' }
    ]
    
    const level = levels[strength]
    
    // Update fill
    this.fillTarget.setAttribute('data-strength', strength)
    
    // Update text
    if (this.hasLevelTarget) {
      this.levelTarget.textContent = level.text
      this.levelTarget.className = `calm-text-${level.color}`
    }
    
    // Show/hide indicator
    if (this.hasIndicatorTarget) {
      this.indicatorTarget.hidden = !this.inputTarget.value
    }
    
    // Dispatch event for form validation
    this.dispatch('strengthChanged', {
      detail: { strength, level: level.text }
    })
  }
}