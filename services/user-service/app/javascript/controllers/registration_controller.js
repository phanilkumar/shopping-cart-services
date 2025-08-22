import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "modal", "email"]

  connect() {
    console.log("Registration controller connected")
  }

  // Handle form submission
  submit(event) {
    // Form will be handled by Turbo
    console.log("Form submitted")
  }

  // Show congratulations modal
  showCongratulations(event) {
    if (event.detail.success) {
      this.modalTarget.classList.remove("hidden")
    }
  }

  // Hide congratulations modal
  hideCongratulations() {
    this.modalTarget.classList.add("hidden")
  }

  // Navigate to login
  goToLogin() {
    this.hideCongratulations()
    window.location.href = "/login"
  }

  // Real-time validation
  validateField(event) {
    const field = event.target
    const value = field.value
    const fieldName = field.name

    // Remove existing error styling
    field.classList.remove("border-red-500")
    this.removeErrorMessage(field)

    // Basic validation
    if (fieldName === "email" && value && !this.isValidEmail(value)) {
      this.showFieldError(field, "Please enter a valid email address")
    }

    if (fieldName === "phone" && value && !this.isValidPhone(value)) {
      this.showFieldError(field, "Please enter a valid 10-digit phone number")
    }

    if (fieldName === "password" && value && value.length < 6) {
      this.showFieldError(field, "Password must be at least 6 characters")
    }
  }

  // Helper methods
  isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    return emailRegex.test(email)
  }

  isValidPhone(phone) {
    const phoneRegex = /^[6-9]\d{9}$/
    return phoneRegex.test(phone.replace(/\D/g, ''))
  }

  showFieldError(field, message) {
    field.classList.add("border-red-500")
    const errorDiv = document.createElement("div")
    errorDiv.className = "text-red-500 text-sm mt-1"
    errorDiv.textContent = message
    errorDiv.id = `${field.name}_error`
    field.parentNode.appendChild(errorDiv)
  }

  removeErrorMessage(field) {
    const existingError = document.getElementById(`${field.name}_error`)
    if (existingError) {
      existingError.remove()
    }
  }
}
