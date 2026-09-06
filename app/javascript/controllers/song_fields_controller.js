import { Controller } from "@hotwired/stimulus"

// Manages the repeatable "song" rows on the submission form and keeps a live
// price total in sync ($PRICE per uploaded song).
export default class extends Controller {
  static targets = ["rows", "template", "total", "count", "submitButton", "spinner", "submitLabel"]
  static values = { pricePerSong: Number }

  connect() {
    this.updateTotal()
  }

  uploadStart() {
    this.submitButtonTarget.disabled = true
    this.spinnerTarget.classList.remove("hidden")
    this.submitLabelTarget.textContent = "Uploading…"
  }

  uploadEnd() {
    this.submitLabelTarget.textContent = "Redirecting to payment…"
  }

  uploadError() {
    this.submitButtonTarget.disabled = false
    this.spinnerTarget.classList.add("hidden")
    this.submitLabelTarget.textContent = "Continue to payment"
  }

  async fileSelected(event) {
    const file = event.target.files && event.target.files[0]
    if (!file) return

    const tags = await this.readId3Tags(file)
    if (!tags) return

    const row = event.target.closest("[data-song-row]")
    const titleInput = row && row.querySelector("input[type=text]")
    if (titleInput && !titleInput.value.trim() && tags.title) {
      titleInput.value = tags.title
    }

    const artistInput = this.element.querySelector("input[name='submission[artist_name]']")
    if (artistInput && !artistInput.value.trim() && tags.artist) {
      artistInput.value = tags.artist
    }
  }

  // Minimal ID3v2 reader — just enough to pull the title (TIT2) and artist
  // (TPE1) frames out of an mp3 so we can prefill blank fields. Returns null
  // for anything else (no ID3v2 header, unsupported format, parse failure).
  async readId3Tags(file) {
    try {
      const header = new Uint8Array(await file.slice(0, 10).arrayBuffer())
      if (header[0] !== 0x49 || header[1] !== 0x44 || header[2] !== 0x33) return null // "ID3"

      const version = header[3]
      const tagSize = ((header[6] & 0x7f) << 21) | ((header[7] & 0x7f) << 14) |
                       ((header[8] & 0x7f) << 7) | (header[9] & 0x7f)
      const bytes = new Uint8Array(await file.slice(10, 10 + tagSize).arrayBuffer())

      let offset = 0
      let title = null
      let artist = null

      while (offset + 10 <= bytes.length) {
        const frameId = String.fromCharCode(...bytes.slice(offset, offset + 4))
        if (frameId === "\0\0\0\0") break

        const frameSize = version >= 4
          ? ((bytes[offset + 4] & 0x7f) << 21) | ((bytes[offset + 5] & 0x7f) << 14) |
            ((bytes[offset + 6] & 0x7f) << 7) | (bytes[offset + 7] & 0x7f)
          : (bytes[offset + 4] << 24) | (bytes[offset + 5] << 16) | (bytes[offset + 6] << 8) | bytes[offset + 7]

        const frameStart = offset + 10
        const frameEnd = frameStart + frameSize
        if (frameSize <= 0 || frameEnd > bytes.length) break

        if (frameId === "TIT2") title = this.decodeId3Text(bytes.slice(frameStart, frameEnd))
        if (frameId === "TPE1") artist = this.decodeId3Text(bytes.slice(frameStart, frameEnd))

        offset = frameEnd
      }

      return (title || artist) ? { title, artist } : null
    } catch {
      return null
    }
  }

  decodeId3Text(bytes) {
    const encodingByte = bytes[0]
    const content = bytes.slice(1)
    const decoder = { 1: "utf-16", 2: "utf-16be", 3: "utf-8" }[encodingByte]
      ? new TextDecoder({ 1: "utf-16", 2: "utf-16be", 3: "utf-8" }[encodingByte])
      : new TextDecoder("iso-8859-1")
    return decoder.decode(content).replace(/\u0000+$/, "").trim() || null
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
