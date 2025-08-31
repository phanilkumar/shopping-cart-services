import { Controller } from "@hotwired/stimulus"

// Home page controller for peaceful animations
export default class extends Controller {
  connect() {
    this.observeAnimations()
  }
  
  observeAnimations() {
    // Create intersection observer for fade-in animations
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            entry.target.classList.add('animate-visible')
          }
        })
      },
      {
        threshold: 0.1,
        rootMargin: '50px'
      }
    )
    
    // Observe all elements with animation classes
    const animatedElements = this.element.querySelectorAll('.animate-fade-in')
    animatedElements.forEach(el => observer.observe(el))
  }
}