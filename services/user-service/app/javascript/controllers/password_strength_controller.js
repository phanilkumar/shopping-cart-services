import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["password", "progress", "strength", "requirements"]
  static values = { 
    minLength: { type: Number, default: 8 },
    maxLength: { type: Number, default: 16 }
  }

  connect() {
    console.log("Password strength controller connected!")
    console.log("Password target:", this.passwordTarget)
    console.log("Progress target:", this.progressTarget)
    console.log("Strength target:", this.strengthTarget)
    console.log("Requirements targets:", this.requirementsTargets)
    
    this.updatePasswordStrength()
  }

  updatePasswordStrength() {
    console.log("updatePasswordStrength called")
    const password = this.passwordTarget.value
    console.log("Password value:", password)
    
    const strength = this.calculatePasswordStrength(password)
    console.log("Calculated strength:", strength)
    
    this.updateProgressBar(strength)
    this.updateStrengthText(strength)
    this.updateRequirements(password)
  }

  calculatePasswordStrength(password) {
    if (!password) return 0

    let score = 0
    const checks = {
      length: password.length >= this.minLengthValue && password.length <= this.maxLengthValue,
      letter: /[a-zA-Z]/.test(password),
      number: /\d/.test(password),
      special: /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password),
      validChars: /^[a-zA-Z0-9!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]+$/.test(password)
    }

    console.log("Password checks:", checks)

    // Base score for each requirement met
    Object.values(checks).forEach(check => {
      if (check) score += 20
    })

    // Bonus for length (up to 20 points)
    if (password.length >= 12) score += 20
    else if (password.length >= 10) score += 10

    return Math.min(score, 100)
  }

  updateProgressBar(strength) {
    console.log("Updating progress bar to:", strength)
    const progressBar = this.progressTarget
    const percentage = strength

    // Update width
    progressBar.style.width = `${percentage}%`

    // Update color based on strength
    progressBar.className = this.getProgressBarClasses(strength)
  }

  getProgressBarClasses(strength) {
    const baseClasses = "h-2 rounded-full transition-all duration-300 ease-in-out password-strength-bar"
    
    if (strength >= 80) {
      return `${baseClasses} very-strong`
    } else if (strength >= 60) {
      return `${baseClasses} strong`
    } else if (strength >= 40) {
      return `${baseClasses} medium`
    } else if (strength >= 20) {
      return `${baseClasses} weak`
    } else {
      return `${baseClasses} very-weak`
    }
  }

  updateStrengthText(strength) {
    console.log("Updating strength text to:", strength)
    const strengthText = this.strengthTarget
    let text = ""
    let textColor = ""

    if (strength >= 80) {
      text = "Very Strong"
      textColor = "text-green-600"
    } else if (strength >= 60) {
      text = "Strong"
      textColor = "text-blue-600"
    } else if (strength >= 40) {
      text = "Medium"
      textColor = "text-yellow-600"
    } else if (strength >= 20) {
      text = "Weak"
      textColor = "text-orange-600"
    } else {
      text = "Very Weak"
      textColor = "text-red-600"
    }

    strengthText.textContent = text
    strengthText.className = `text-xs font-medium ${textColor}`
  }

  updateRequirements(password) {
    console.log("Updating requirements for password:", password)
    const requirements = this.requirementsTargets
    const checks = {
      length: password.length >= this.minLengthValue && password.length <= this.maxLengthValue,
      letter: /[a-zA-Z]/.test(password),
      number: /\d/.test(password),
      special: /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password),
      validChars: /^[a-zA-Z0-9!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]+$/.test(password)
    }

    requirements.forEach((requirement, index) => {
      const check = Object.values(checks)[index]
      const icon = requirement.querySelector('.requirement-icon')
      const text = requirement.querySelector('.requirement-text')
      
      if (check) {
        icon.innerHTML = '<svg class="w-4 h-4 text-green-500" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path></svg>'
        text.classList.remove('text-gray-400')
        text.classList.add('text-green-600')
      } else {
        icon.innerHTML = '<svg class="w-4 h-4 text-gray-400" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-11a1 1 0 10-2 0v2H7a1 1 0 100 2h2v2a1 1 0 102 0v-2h2a1 1 0 100-2h-2V7z" clip-rule="evenodd"></path></svg>'
        text.classList.remove('text-green-600')
        text.classList.add('text-gray-400')
      }
    })
  }
}
