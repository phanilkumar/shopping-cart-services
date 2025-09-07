import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["password", "confirmPassword", "strengthIndicator", "requirements", "lockoutWarning", "twoFactorSetup"]
  static values = { 
    minLength: { type: Number, default: 8 },
    maxLength: { type: Number, default: 16 },
    userId: Number
  }

  connect() {
    console.log("Security controller connected!")
    this.initializePasswordValidation()
    this.checkAccountStatus()
  }

  initializePasswordValidation() {
    if (this.hasPasswordTarget) {
      this.passwordTarget.addEventListener('input', () => this.validatePassword())
      this.passwordTarget.addEventListener('blur', () => this.validatePassword())
    }

    if (this.hasConfirmPasswordTarget) {
      this.confirmPasswordTarget.addEventListener('input', () => this.validatePasswordMatch())
    }
  }

  validatePassword() {
    const password = this.passwordTarget.value
    const strength = this.calculatePasswordStrength(password)
    
    this.updateStrengthIndicator(strength)
    this.updateRequirements(password)
    this.validatePasswordMatch()
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

    // Base score for each requirement met
    Object.values(checks).forEach(check => {
      if (check) score += 20
    })

    // Bonus for length
    if (password.length >= 12) score += 20
    else if (password.length >= 10) score += 10

    // Penalty for common patterns
    if (this.isCommonPassword(password)) score -= 30

    return Math.max(0, Math.min(score, 100))
  }

  isCommonPassword(password) {
    const commonPasswords = [
      'password', '123456', '123456789', 'qwerty', 'abc123',
      'password123', 'admin', 'letmein', 'welcome', 'monkey',
      '12345678', '1234567', '1234567890', 'password1', '123123'
    ]
    
    return commonPasswords.includes(password.toLowerCase())
  }

  updateStrengthIndicator(strength) {
    if (!this.hasStrengthIndicatorTarget) return

    const indicator = this.strengthIndicatorTarget
    let color = 'red'
    let text = 'Very Weak'

    if (strength >= 80) {
      color = 'green'
      text = 'Very Strong'
    } else if (strength >= 60) {
      color = 'blue'
      text = 'Strong'
    } else if (strength >= 40) {
      color = 'orange'
      text = 'Medium'
    } else if (strength >= 20) {
      color = 'yellow'
      text = 'Weak'
    }

    indicator.style.color = color
    indicator.textContent = text
  }

  updateRequirements(password) {
    if (!this.hasRequirementsTarget) return

    const requirements = this.requirementsTargets
    const checks = {
      length: password.length >= this.minLengthValue && password.length <= this.maxLengthValue,
      letter: /[a-zA-Z]/.test(password),
      number: /\d/.test(password),
      special: /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password)
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

  validatePasswordMatch() {
    if (!this.hasPasswordTarget || !this.hasConfirmPasswordTarget) return

    const password = this.passwordTarget.value
    const confirmPassword = this.confirmPasswordTarget.value

    if (confirmPassword && password !== confirmPassword) {
      this.confirmPasswordTarget.setCustomValidity('Passwords do not match')
    } else {
      this.confirmPasswordTarget.setCustomValidity('')
    }
  }

  async checkAccountStatus() {
    if (!this.userIdValue) return

    try {
      const response = await fetch('/security/status', {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]')?.content
        }
      })

      if (response.ok) {
        const data = await response.json()
        this.updateSecurityStatus(data.data)
      }
    } catch (error) {
      console.error('Error checking account status:', error)
    }
  }

  updateSecurityStatus(status) {
    // Show lockout warning if account is locked
    if (status.account_locked && this.hasLockoutWarningTarget) {
      this.lockoutWarningTarget.classList.remove('hidden')
      this.lockoutWarningTarget.innerHTML = `
        <div class="bg-red-50 border border-red-200 rounded-md p-4">
          <div class="flex">
            <div class="flex-shrink-0">
              <svg class="h-5 w-5 text-red-400" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"></path>
              </svg>
            </div>
            <div class="ml-3">
              <h3 class="text-sm font-medium text-red-800">Account Locked</h3>
              <div class="mt-2 text-sm text-red-700">
                <p>Your account has been locked due to multiple failed login attempts. Please contact support.</p>
              </div>
            </div>
          </div>
        </div>
      `
    }

    // Show 2FA setup if not enabled
    if (!status.two_factor_enabled && this.hasTwoFactorSetupTarget) {
      this.twoFactorSetupTarget.classList.remove('hidden')
    }
  }

  async enableTwoFactor() {
    try {
      const response = await fetch('/security/enable-2fa', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]')?.content
        }
      })

      if (response.ok) {
        const data = await response.json()
        this.showTwoFactorSetup(data.data)
      } else {
        const error = await response.json()
        this.showError(error.message)
      }
    } catch (error) {
      console.error('Error enabling 2FA:', error)
      this.showError('Failed to enable two-factor authentication')
    }
  }

  showTwoFactorSetup(data) {
    // Create QR code display
    const qrCodeContainer = document.createElement('div')
    qrCodeContainer.className = 'mt-4 p-4 bg-gray-50 rounded-md'
    qrCodeContainer.innerHTML = `
      <h3 class="text-lg font-medium text-gray-900 mb-2">Two-Factor Authentication Setup</h3>
      <p class="text-sm text-gray-600 mb-4">Scan this QR code with your authenticator app:</p>
      <div class="text-center">
        <div id="qrcode" class="inline-block"></div>
      </div>
      <p class="text-sm text-gray-600 mt-4">Or enter this code manually: <code class="bg-gray-200 px-2 py-1 rounded">${data.secret}</code></p>
    `

    this.twoFactorSetupTarget.appendChild(qrCodeContainer)

    // Generate QR code (requires qrcode.js library)
    if (typeof QRCode !== 'undefined') {
      new QRCode(document.getElementById('qrcode'), data.qr_code_uri)
    }
  }

  showError(message) {
    // Create error notification
    const errorDiv = document.createElement('div')
    errorDiv.className = 'fixed top-4 right-4 bg-red-500 text-white px-4 py-2 rounded shadow-lg z-50'
    errorDiv.textContent = message
    
    document.body.appendChild(errorDiv)
    
    setTimeout(() => {
      errorDiv.remove()
    }, 5000)
  }

  // Form validation before submission
  validateForm(event) {
    const password = this.passwordTarget?.value
    const confirmPassword = this.confirmPasswordTarget?.value

    if (password && this.calculatePasswordStrength(password) < 40) {
      event.preventDefault()
      this.showError('Password is too weak. Please choose a stronger password.')
      return false
    }

    if (confirmPassword && password !== confirmPassword) {
      event.preventDefault()
      this.showError('Passwords do not match.')
      return false
    }

    return true
  }
}



