import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "toggleText"]
  
  connect() {
    this.isExpanded = true
    this.contentTarget.style.maxHeight = this.contentTarget.scrollHeight + "px"
    this.toggleTextTarget.textContent = "Hide"
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
    this.toggleTextTarget.textContent = "Hide"
    this.isExpanded = true
  }

  collapse() {
    this.contentTarget.style.maxHeight = "0px"
    this.toggleTextTarget.textContent = "View"
    this.isExpanded = false
  }
}