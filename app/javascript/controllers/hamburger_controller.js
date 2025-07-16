import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.menuTarget.classList.add("hidden")
    this.handleClickOutside = this.handleClickOutside.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside)
  }

  toggle() {
    this.menuTarget.classList.toggle("hidden")
    
    if (this.menuTarget.classList.contains("hidden")) {
      document.removeEventListener("click", this.handleClickOutside)
    } else {
      setTimeout(() => {
        document.addEventListener("click", this.handleClickOutside)
      }, 0)
    }
  }

  hide() {
    this.menuTarget.classList.add("hidden")
    document.removeEventListener("click", this.handleClickOutside)
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hide()
    }
  }
}