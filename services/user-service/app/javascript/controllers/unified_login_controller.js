import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "emailTab", "phoneTab", "emailLogin", "phoneLogin", "phoneStep", "otpStep",
    "phoneInput", "otp1", "otp2", "otp3", "otp4", "otp5", "otp6",
    "sendOtpBtn", "verifyOtpBtn", "resendOtpBtn", "loadingOverlay", "toastContainer"
  ]

  connect() {
    console.log('UnifiedLoginController connected!')
    this.currentPhone = null
    this.otpInputs = [this.otp1Target, this.otp2Target, this.otp3Target, this.otp4Target, this.otp5Target, this.otp6Target]
    this.setupOtpInputs()
  }

  // Tab switching
  switchToEmail() {
    console.log('Switching to email tab')
    this.emailTabTarget.classList.add('bg-white', 'text-blue-600', 'shadow-sm')
    this.emailTabTarget.classList.remove('text-gray-600', 'hover:text-gray-900')
    
    this.phoneTabTarget.classList.remove('bg-white', 'text-blue-600', 'shadow-sm')
    this.phoneTabTarget.classList.add('text-gray-600', 'hover:text-gray-900')
    
    this.emailLoginTarget.classList.remove('hidden')
    this.phoneLoginTarget.classList.add('hidden')
  }

  switchToPhone() {
    console.log('Switching to phone tab')
    this.phoneTabTarget.classList.add('bg-white', 'text-blue-600', 'shadow-sm')
    this.phoneTabTarget.classList.remove('text-gray-600', 'hover:text-gray-900')
    
    this.emailTabTarget.classList.remove('bg-white', 'text-blue-600', 'shadow-sm')
    this.emailTabTarget.classList.add('text-gray-600', 'hover:text-gray-900')
    
    this.phoneLoginTarget.classList.remove('hidden')
    this.emailLoginTarget.classList.add('hidden')
  }

  // Phone OTP functionality
  async sendOtp() {
    const phone = this.phoneInputTarget.value.trim()
    
    if (!this.validatePhone(phone)) {
      this.showToast('Please enter a valid 10-digit phone number', 'error')
      return
    }

    this.showLoading(true)
    
    try {
      const response = await fetch('/api/v1/auth/otp/send', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ phone: phone })
      })

      const data = await response.json()
      
      if (data.status === 'success') {
        this.currentPhone = phone
        this.showOtpStep()
        this.showToast(data.message, 'success')
      } else {
        this.showToast(data.message, 'error')
      }
    } catch (error) {
      this.showToast('Network error. Please try again.', 'error')
    } finally {
      this.showLoading(false)
    }
  }

  showOtpStep() {
    this.phoneStepTarget.classList.add('hidden')
    this.otpStepTarget.classList.remove('hidden')
    this.otp1Target.focus()
  }

  backToPhone() {
    this.otpStepTarget.classList.add('hidden')
    this.phoneStepTarget.classList.remove('hidden')
    this.currentPhone = null
    this.clearOtpInputs()
  }

  async verifyOtp() {
    const otp = this.getOtpValue()
    
    if (otp.length !== 6) {
      this.showToast('Please enter the complete 6-digit OTP', 'error')
      return
    }

    this.showLoading(true)
    
    try {
      const response = await fetch('/api/v1/auth/otp/verify', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ 
          phone: this.currentPhone, 
          otp: otp 
        })
      })

      const data = await response.json()
      
      if (data.status === 'success') {
        this.showToast('OTP verified successfully!', 'success')
        // Redirect to dashboard or congratulations page
        setTimeout(() => {
          window.location.href = '/congratulations'
        }, 1000)
      } else {
        this.showToast(data.message, 'error')
      }
    } catch (error) {
      this.showToast('Network error. Please try again.', 'error')
    } finally {
      this.showLoading(false)
    }
  }

  async resendOtp() {
    if (!this.currentPhone) {
      this.showToast('Please enter a phone number first', 'error')
      return
    }

    this.showLoading(true)
    
    try {
      const response = await fetch('/api/v1/auth/otp/send', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ phone: this.currentPhone })
      })

      const data = await response.json()
      
      if (data.status === 'success') {
        this.showToast(data.message, 'success')
        this.clearOtpInputs()
        this.otp1Target.focus()
      } else {
        this.showToast(data.message, 'error')
      }
    } catch (error) {
      this.showToast('Network error. Please try again.', 'error')
    } finally {
      this.showLoading(false)
    }
  }

  // OTP Input handling
  setupOtpInputs() {
    this.otpInputs.forEach((input, index) => {
      input.addEventListener('input', (e) => {
        this.handleOtpInput(e, index)
      })
      
      input.addEventListener('keydown', (e) => {
        this.handleOtpKeydown(e, index)
      })
    })
  }

  handleOtpInput(event, index) {
    const input = event.target
    const value = input.value.replace(/\D/g, '').slice(0, 2)
    input.value = value

    if (value.length === 2 && index < 5) {
      this.otpInputs[index + 1].focus()
    }
  }

  handleOtpKeydown(event, index) {
    if (event.key === 'Backspace' && event.target.value === '' && index > 0) {
      this.otpInputs[index - 1].focus()
    }
  }

  getOtpValue() {
    return this.otpInputs.map(input => input.value).join('')
  }

  clearOtpInputs() {
    this.otpInputs.forEach(input => {
      input.value = ''
    })
  }

  // Validation
  validatePhone(phone) {
    return /^[6-9]\d{9}$/.test(phone)
  }

  // UI helpers
  showLoading(show) {
    if (show) {
      this.loadingOverlayTarget.classList.remove('hidden')
    } else {
      this.loadingOverlayTarget.classList.add('hidden')
    }
  }

  showToast(message, type = 'info') {
    const toast = document.createElement('div')
    const bgColor = type === 'success' ? 'bg-green-500' : type === 'error' ? 'bg-red-500' : 'bg-blue-500'
    const icon = type === 'success' ? '✓' : type === 'error' ? '✕' : 'ℹ'
    
    toast.className = `${bgColor} text-white px-4 py-3 rounded-lg shadow-lg flex items-center space-x-2 transform transition-all duration-300 translate-x-full`
    toast.innerHTML = `
      <span class="font-bold">${icon}</span>
      <span>${message}</span>
    `
    
    this.toastContainerTarget.appendChild(toast)
    
    // Animate in
    setTimeout(() => {
      toast.classList.remove('translate-x-full')
    }, 100)
    
    // Auto remove after 4 seconds
    setTimeout(() => {
      toast.classList.add('translate-x-full')
      setTimeout(() => {
        if (toast.parentNode) {
          toast.parentNode.removeChild(toast)
        }
      }, 300)
    }, 4000)
  }
}
