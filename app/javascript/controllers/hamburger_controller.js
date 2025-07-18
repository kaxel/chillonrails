import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.menuTarget.classList.add("opacity-0", "scale-95", "pointer-events-none")
    this.menuTarget.classList.add("transform", "transition-all", "duration-200", "ease-out")
    this.handleClickOutside = this.handleClickOutside.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside)
  }

  toggle() {
    const isHidden = this.menuTarget.classList.contains("opacity-0")
    
    if (isHidden) {
      this.show()
    } else {
      this.hide()
    }
  }

  show() {
    this.menuTarget.classList.remove("opacity-0", "scale-95", "pointer-events-none")
    this.menuTarget.classList.add("opacity-100", "scale-100")
    setTimeout(() => {
      document.addEventListener("click", this.handleClickOutside)
    }, 0)
  }

  hide() {
    this.menuTarget.classList.remove("opacity-100", "scale-100")
    this.menuTarget.classList.add("opacity-0", "scale-95", "pointer-events-none")
    document.removeEventListener("click", this.handleClickOutside)
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hide()
    }
  }
}