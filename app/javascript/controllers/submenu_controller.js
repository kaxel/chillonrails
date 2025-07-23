import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]
  
  connect() {
    this.isExpanded = false
  }

  toggle() {
    if (this.isExpanded) {
      this.collapse()
    } else {
      this.expand()
    }
  }

  expand() {
    this.contentTarget.style.maxHeight = this.contentTarget.scrollHeight + "px"
    this.contentTarget.classList.remove("max-h-0")
    this.iconTarget.style.transform = "rotate(90deg)"
    this.isExpanded = true
  }

  collapse() {
    this.contentTarget.style.maxHeight = "0px"
    this.contentTarget.classList.add("max-h-0")
    this.iconTarget.style.transform = "rotate(0deg)"
    this.isExpanded = false
  }
}