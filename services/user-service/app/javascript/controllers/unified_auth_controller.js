import { Controller } from "@hotwired/stimulus"

// Unified authentication controller for email and phone login with OTP
export default class extends Controller {
  static targets = [
    "emailTab", "phoneTab", "emailLogin", "phoneLogin", 
    "phoneStep", "otpStep", "phoneInput", "phoneDisplay",
    "otp1", "otp2", "otp3", "otp4", "otp5", "otp6",
    "sendOtpBtn", "verifyOtpBtn", "verifyText", "verifyDisabledText",
    "resendOtpBtn", "resendText", "resendTimer", "timerCountdown",
    "phoneError", "loadingOverlay"
  ]
  
  connect() {
    this.currentPhone = null
    this.otpInputs = [
      this.otp1Target, this.otp2Target, this.otp3Target,
      this.otp4Target, this.otp5Target, this.otp6Target
    ]
    this.setupOtpInputs()
    this.resendTimer = null
    this.countdownInterval = null
    this.failedAttempts = 0
    this.maxFailedAttempts = 3
  }
  
  disconnect() {
    this.stopResendTimer()
  }
  
  // Tab switching
  switchToEmail() {
    this.emailTabTarget.classList.add('active')
    this.phoneTabTarget.classList.remove('active')
    this.emailTabTarget.setAttribute('aria-selected', 'true')
    this.phoneTabTarget.setAttribute('aria-selected', 'false')
    
    this.emailLoginTarget.classList.remove('hidden')
    this.phoneLoginTarget.classList.add('hidden')
  }
  
  switchToPhone() {
    this.phoneTabTarget.classList.add('active')
    this.emailTabTarget.classList.remove('active')
    this.phoneTabTarget.setAttribute('aria-selected', 'true')
    this.emailTabTarget.setAttribute('aria-selected', 'false')
    
    this.phoneLoginTarget.classList.remove('hidden')
    this.emailLoginTarget.classList.add('hidden')
  }
  
  // Phone OTP functionality
  async sendOtp(event) {
    event.preventDefault()
    
    const phone = this.phoneInputTarget.value.trim()
    
    if (!this.validatePhone(phone)) {
      this.showPhoneError('Please enter a valid 10-digit phone number')
      return
    }
    
    this.sendOtpBtnTarget.disabled = true
    this.sendOtpBtnTarget.textContent = 'Sending...'
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
        this.phoneDisplayTarget.textContent = `+91 ${phone}`
        this.showOtpStep()
        this.startResendTimer()
        this.showToast('OTP sent successfully!', 'success')
      } else {
        this.showPhoneError(data.message || 'Failed to send OTP')
        this.sendOtpBtnTarget.disabled = false
        this.sendOtpBtnTarget.textContent = 'Send OTP'
      }
    } catch (error) {
      this.showPhoneError('Network error. Please try again.')
      this.sendOtpBtnTarget.disabled = false
      this.sendOtpBtnTarget.textContent = 'Send OTP'
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
    this.stopResendTimer()
    this.resetVerifyButton()
    this.sendOtpBtnTarget.disabled = false
    this.sendOtpBtnTarget.textContent = 'Send OTP'
  }
  
  async verifyOtp() {
    if (this.verifyOtpBtnTarget.disabled) {
      return
    }
    
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
        setTimeout(() => {
          window.location.href = '/congratulations'
        }, 1000)
      } else {
        this.failedAttempts++
        this.showToast(data.message || 'Invalid OTP', 'error')
        
        if (this.failedAttempts >= this.maxFailedAttempts) {
          this.disableVerifyButton()
          this.showToast('Too many failed attempts. Please request a new OTP.', 'error')
        }
      }
    } catch (error) {
      this.failedAttempts++
      this.showToast('Network error. Please try again.', 'error')
      
      if (this.failedAttempts >= this.maxFailedAttempts) {
        this.disableVerifyButton()
      }
    } finally {
      this.showLoading(false)
    }
  }
  
  async resendOtp() {
    if (this.resendOtpBtnTarget.disabled || !this.currentPhone) {
      return
    }
    
    this.resendOtpBtnTarget.disabled = true
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
        this.showToast('OTP resent successfully!', 'success')
        this.clearOtpInputs()
        this.otp1Target.focus()
        this.startResendTimer()
        this.resetVerifyButton()
      } else {
        this.showToast(data.message || 'Failed to resend OTP', 'error')
        this.resendOtpBtnTarget.disabled = false
      }
    } catch (error) {
      this.showToast('Network error. Please try again.', 'error')
      this.resendOtpBtnTarget.disabled = false
    } finally {
      this.showLoading(false)
    }
  }
  
  // OTP Input handling
  setupOtpInputs() {
    this.otpInputs.forEach((input, index) => {
      input.addEventListener('input', (e) => this.handleOtpInput(e, index))
      input.addEventListener('keydown', (e) => this.handleOtpKeydown(e, index))
      input.addEventListener('paste', (e) => this.handleOtpPaste(e))
    })
  }
  
  handleOtpInput(event, index) {
    const input = event.target
    const value = input.value.replace(/\D/g, '').slice(0, 1)
    input.value = value
    
    if (value.length === 1 && index < 5) {
      this.otpInputs[index + 1].focus()
    }
  }
  
  handleOtpKeydown(event, index) {
    if (event.key === 'Backspace' && event.target.value === '' && index > 0) {
      this.otpInputs[index - 1].focus()
    }
    
    if (event.key === 'ArrowLeft' && index > 0) {
      this.otpInputs[index - 1].focus()
    }
    
    if (event.key === 'ArrowRight' && index < 5) {
      this.otpInputs[index + 1].focus()
    }
  }
  
  handleOtpPaste(event) {
    event.preventDefault()
    const pastedData = event.clipboardData.getData('text').replace(/\D/g, '').slice(0, 6)
    
    pastedData.split('').forEach((digit, index) => {
      if (this.otpInputs[index]) {
        this.otpInputs[index].value = digit
      }
    })
    
    if (pastedData.length === 6) {
      this.otpInputs[5].focus()
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
  
  // Timer functionality
  startResendTimer() {
    if (this.countdownInterval) {
      clearInterval(this.countdownInterval)
    }
    
    let countdown = 60
    this.resendOtpBtnTarget.disabled = true
    this.resendTextTarget.classList.add('hidden')
    this.resendTimerTarget.classList.remove('hidden')
    this.timerCountdownTarget.textContent = countdown
    
    this.countdownInterval = setInterval(() => {
      countdown--
      this.timerCountdownTarget.textContent = countdown
      
      if (countdown <= 0) {
        clearInterval(this.countdownInterval)
        this.resendOtpBtnTarget.disabled = false
        this.resendTextTarget.classList.remove('hidden')
        this.resendTimerTarget.classList.add('hidden')
      }
    }, 1000)
  }
  
  stopResendTimer() {
    if (this.countdownInterval) {
      clearInterval(this.countdownInterval)
      this.countdownInterval = null
    }
    this.resendOtpBtnTarget.disabled = false
    this.resendTextTarget.classList.remove('hidden')
    this.resendTimerTarget.classList.add('hidden')
  }
  
  // UI helpers
  disableVerifyButton() {
    this.verifyOtpBtnTarget.disabled = true
    this.verifyTextTarget.classList.add('hidden')
    this.verifyDisabledTextTarget.classList.remove('hidden')
  }
  
  resetVerifyButton() {
    this.verifyOtpBtnTarget.disabled = false
    this.verifyTextTarget.classList.remove('hidden')
    this.verifyDisabledTextTarget.classList.add('hidden')
    this.failedAttempts = 0
  }
  
  validatePhone(phone) {
    return /^[6-9]\d{9}$/.test(phone)
  }
  
  showPhoneError(message) {
    this.phoneErrorTarget.textContent = message
    this.phoneErrorTarget.hidden = false
    setTimeout(() => {
      this.phoneErrorTarget.hidden = true
    }, 5000)
  }
  
  showLoading(show) {
    if (this.hasLoadingOverlayTarget) {
      if (show) {
        this.loadingOverlayTarget.classList.remove('hidden')
      } else {
        this.loadingOverlayTarget.classList.add('hidden')
      }
    }
  }
  
  showToast(message, type = 'info') {
    // Create toast element
    const toast = document.createElement('div')
    toast.className = `calm-toast calm-toast-${type} animate-fade-in`
    toast.innerHTML = `
      <span class="calm-toast-icon">${this.getToastIcon(type)}</span>
      <span class="calm-toast-message">${message}</span>
    `
    
    // Add to container or create one
    let container = document.querySelector('.calm-toast-container')
    if (!container) {
      container = document.createElement('div')
      container.className = 'calm-toast-container'
      document.body.appendChild(container)
    }
    
    container.appendChild(toast)
    
    // Auto remove after 4 seconds
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
  
  // Handle form submission results
  handleSubmitEnd(event) {
    if (event.detail.success) {
      this.showToast('Login successful!', 'success')
    }
  }
}

// Toast container styles
const style = document.createElement('style')
style.textContent = `
  .calm-toast-container {
    position: fixed;
    top: 1rem;
    right: 1rem;
    z-index: 9999;
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }
  
  .calm-toast {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 1rem 1.5rem;
    background: white;
    border-radius: 0.5rem;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
    min-width: 250px;
    transition: opacity 0.3s ease;
  }
  
  .calm-toast-icon {
    width: 1.5rem;
    height: 1.5rem;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 50%;
    font-weight: bold;
    flex-shrink: 0;
  }
  
  .calm-toast-success .calm-toast-icon {
    background: #D4EDDA;
    color: #155724;
  }
  
  .calm-toast-error .calm-toast-icon {
    background: #F8D7DA;
    color: #721C24;
  }
  
  .calm-toast-info .calm-toast-icon {
    background: #D1ECF1;
    color: #0C5460;
  }
  
  .calm-toast-warning .calm-toast-icon {
    background: #FFF3CD;
    color: #856404;
  }
  
  .calm-toast-message {
    color: #212529;
    font-size: 0.875rem;
  }
  
  @media (max-width: 480px) {
    .calm-toast-container {
      left: 1rem;
      right: 1rem;
    }
    
    .calm-toast {
      width: 100%;
    }
  }
`
document.head.appendChild(style)