import { Controller } from "@hotwired/stimulus"

// Manages the repeatable "song" rows on the submission form and keeps a live
// price total in sync ($PRICE per uploaded song).
export default class extends Controller {
  static targets = ["rows", "template", "total", "count"]
  static values = { pricePerSong: Number }

  connect() {
    this.updateTotal()
  }

  add(event) {
    event.preventDefault()
    const index = this.rowsTarget.querySelectorAll("[data-song-row]").length
    const html = this.templateTarget.innerHTML.replace(/__INDEX__/g, index)
    this.rowsTarget.insertAdjacentHTML("beforeend", html)
    this.updateTotal()
  }

  remove(event) {
    event.preventDefault()
    const rows = this.rowsTarget.querySelectorAll("[data-song-row]")
    // Keep at least one row on the form.
    if (rows.length <= 1) return
    event.target.closest("[data-song-row]").remove()
    this.updateTotal()
  }

  updateTotal() {
    const count = this.rowsTarget.querySelectorAll("[data-song-row]").length
    const dollars = ((count * this.pricePerSongValue) / 100).toFixed(2)
    if (this.hasTotalTarget) this.totalTarget.textContent = `$${dollars}`
    if (this.hasCountTarget) this.countTarget.textContent = count
  }
}
