import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "step1", 
    "step2Password", 
    "step2Otp", 
    "identifier", 
    "emailDisplay", 
    "passwordForm", 
    "passwordIdentifier", 
    "passwordInput", 
    "phoneDisplay", 
    "otpForm", 
    "otpIdentifier", 
    "otpInput", 
    "otpError", 
    "passwordError"
  ]

  connect() {
    this.currentStep = 1
    this.identifierType = null
  }

  detectType(event) {
    const value = event.target.value.trim()
    if (value.includes('@')) {
      this.identifierType = 'email'
    } else if (value.match(/^\d+$/)) {
      this.identifierType = 'phone'
    } else {
      this.identifierType = null
    }
  }

  continue() {
    const identifier = this.identifierTarget.value.trim()
    
    if (!identifier) {
      this.showError(this.identifierTarget, 'Please enter your email or phone number')
      return
    }

    if (!this.identifierType) {
      this.showError(this.identifierTarget, 'Please enter a valid email or phone number')
      return
    }

    if (this.identifierType === 'email') {
      this.showPasswordStep(identifier)
    } else {
      this.showOtpStep(identifier)
    }
  }

  showPasswordStep(email) {
    this.step1Target.classList.add('hidden')
    this.step2PasswordTarget.classList.remove('hidden')
    this.emailDisplayTarget.textContent = email
    this.passwordIdentifierTarget.value = email
    this.passwordInputTarget.focus()
  }

  showOtpStep(phone) {
    this.step1Target.classList.add('hidden')
    this.step2OtpTarget.classList.remove('hidden')
    this.phoneDisplayTarget.textContent = phone
    this.otpIdentifierTarget.value = phone
    this.otpInputTarget.focus()
  }

  async authenticateWithPassword(event) {
    event.preventDefault()
    
    const email = this.passwordIdentifierTarget.value
    const password = this.passwordInputTarget.value

    if (!password) {
      this.showError(this.passwordInputTarget, 'Please enter your password')
      return
    }

    try {
      const response = await fetch('/auth/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          email: email,
          password: password
        })
      })

      const data = await response.json()

      if (response.ok) {
        window.location.href = '/dashboard'
      } else {
        this.showError(this.passwordInputTarget, data.error || 'Invalid credentials')
      }
    } catch (error) {
      this.showError(this.passwordInputTarget, 'An error occurred. Please try again.')
    }
  }

  async authenticateWithOtp(event) {
    event.preventDefault()
    
    const phone = this.otpIdentifierTarget.value
    const otp = this.otpInputTarget.value

    if (!otp) {
      this.showError(this.otpInputTarget, 'Please enter the OTP')
      return
    }

    if (otp.length !== 6) {
      this.showError(this.otpInputTarget, 'OTP must be 6 digits')
      return
    }

    try {
      const response = await fetch('/auth/login_with_otp', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          phone: phone,
          otp: otp
        })
      })

      const data = await response.json()

      if (response.ok) {
        window.location.href = '/dashboard'
      } else {
        this.showError(this.otpInputTarget, data.error || 'Invalid OTP')
      }
    } catch (error) {
      this.showError(this.otpInputTarget, 'An error occurred. Please try again.')
    }
  }

  handlePasswordKeydown(event) {
    if (event.key === 'Enter') {
      this.authenticateWithPassword(event)
    }
  }

  handleOtpKeydown(event) {
    if (event.key === 'Enter') {
      this.authenticateWithOtp(event)
    }
  }

  hidePasswordError() {
    this.hideError(this.passwordInputTarget)
  }

  hideOtpError() {
    this.hideError(this.otpInputTarget)
  }

  showError(element, message) {
    this.hideError(element)
    
    const errorDiv = document.createElement('div')
    errorDiv.className = 'text-red-600 text-sm mt-1'
    errorDiv.textContent = message
    
    element.parentNode.appendChild(errorDiv)
    element.classList.add('border-red-500', 'focus:ring-red-500', 'focus:border-red-500')
  }

  hideError(element) {
    const errorDiv = element.parentNode.querySelector('.text-red-600')
    if (errorDiv) {
      errorDiv.remove()
    }
    element.classList.remove('border-red-500', 'focus:ring-red-500', 'focus:border-red-500')
  }

  preventFormSubmit(event) {
    event.preventDefault()
  }

  goBack() {
    this.step2PasswordTarget.classList.add('hidden')
    this.step2OtpTarget.classList.add('hidden')
    this.step1Target.classList.remove('hidden')
    this.identifierTarget.focus()
  }
}
