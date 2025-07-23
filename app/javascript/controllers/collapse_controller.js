import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "toggleText"]
  static values = { hideHero: Boolean }
  
  connect() {
    this.isExpanded = !this.hideHeroValue
    
    if (this.isExpanded) {
      this.contentTarget.style.maxHeight = this.contentTarget.scrollHeight + "px"
      this.toggleTextTarget.textContent = "Hide"
    } else {
      this.contentTarget.style.maxHeight = "0px"
      this.toggleTextTarget.textContent = "View"
    }
  }

  toggle() {
    const url = new URL(window.location)
    
    if (this.isExpanded) {
      this.collapse()
      url.searchParams.set('hide_hero', 'true')
    } else {
      this.expand()
      url.searchParams.delete('hide_hero')
    }
    
    window.history.replaceState({}, '', url)
  }

  expand() {
    this.contentTarget.style.maxHeight = this.contentTarget.scrollHeight + "px"
    this.toggleTextTarget.textContent = "Hide"
    this.isExpanded = true
  }

  collapse() {
    this.contentTarget.style.maxHeight = "0px"
    this.toggleTextTarget.textContent = "View"
    this.isExpanded = false
  }
}