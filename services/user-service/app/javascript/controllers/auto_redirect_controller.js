import { Controller } from "@hotwired/stimulus"

// Auto redirect controller with countdown
export default class extends Controller {
  static targets = ["countdown"]
  static values = { 
    delay: { type: Number, default: 10 },
    url: { type: String, default: "/dashboard" }
  }
  
  connect() {
    this.countdown = this.delayValue
    this.cancelled = false
    this.startCountdown()
  }
  
  disconnect() {
    this.cancel()
  }
  
  startCountdown() {
    this.updateDisplay()
    
    this.interval = setInterval(() => {
      if (this.cancelled) return
      
      this.countdown--
      this.updateDisplay()
      
      if (this.countdown <= 0) {
        this.redirect()
      }
    }, 1000)
  }
  
  updateDisplay() {
    if (this.hasCountdownTarget) {
      this.countdownTarget.textContent = this.countdown
    }
  }
  
  redirect() {
    if (!this.cancelled) {
      window.location.href = this.urlValue
    }
  }
  
  cancel() {
    this.cancelled = true
    if (this.interval) {
      clearInterval(this.interval)
    }
    
    // Update UI to show cancellation
    if (this.hasCountdownTarget) {
      this.countdownTarget.textContent = '∞'
    }
    
    // Hide the redirect notice
    const notice = this.element.querySelector('.calm-redirect-text')
    if (notice) {
      notice.innerHTML = 'Auto-redirect cancelled. Take your time to explore!'
    }
  }
}