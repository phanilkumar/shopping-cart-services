import { Controller } from "@hotwired/stimulus"

// Dashboard controller for interactive features
export default class extends Controller {
  connect() {
    // Add any dashboard-specific functionality here
    this.animateStats()
  }
  
  animateStats() {
    // Animate stat values on load
    const statValues = this.element.querySelectorAll('.calm-stat-value')
    
    statValues.forEach(stat => {
      const finalValue = parseInt(stat.textContent)
      if (!isNaN(finalValue)) {
        stat.textContent = '0'
        this.animateValue(stat, 0, finalValue, 1000)
      }
    })
  }
  
  animateValue(element, start, end, duration) {
    const range = end - start
    const minTimer = 50
    let stepTime = Math.abs(Math.floor(duration / range))
    stepTime = Math.max(stepTime, minTimer)
    
    const startTime = new Date().getTime()
    const endTime = startTime + duration
    let timer
    
    function run() {
      const now = new Date().getTime()
      const remaining = Math.max((endTime - now) / duration, 0)
      const value = Math.round(end - (remaining * range))
      element.textContent = value
      
      if (value === end) {
        clearInterval(timer)
      }
    }
    
    timer = setInterval(run, stepTime)
    run()
  }
}