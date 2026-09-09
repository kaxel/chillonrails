import { Controller } from "@hotwired/stimulus"

// Wires a post's tracklist links (<a data-seek="123"> inside the sanitized
// post content) to the Mixcloud embed above it, so clicking a track jumps
// the player there instead of navigating away — same behavior as
// weeklycatch.org's own episode pages, via Mixcloud's official widget API.
export default class extends Controller {
  static targets = ["iframe"]

  connect() {
    if (this.hasIframeTarget) this.loadWidgetApi()
    this.onClick = this.onClick.bind(this)
    this.element.addEventListener("click", this.onClick)
  }

  disconnect() {
    this.element.removeEventListener("click", this.onClick)
  }

  onClick(event) {
    const link = event.target.closest("[data-seek]")
    if (!link || !this.hasIframeTarget) return

    const seconds = parseInt(link.dataset.seek, 10)
    if (Number.isNaN(seconds)) return

    event.preventDefault()

    this.loadWidgetApi()
      .then(() => {
        if (!this.widget) this.widget = Mixcloud.PlayerWidget(this.iframeTarget)
        return this.widget.ready
      })
      .then(() => {
        this.widget.seek(seconds)
        this.widget.play()
      })
  }

  loadWidgetApi() {
    if (window.Mixcloud) return Promise.resolve()
    if (!window.__mixcloudWidgetApiPromise) {
      window.__mixcloudWidgetApiPromise = new Promise((resolve, reject) => {
        const script = document.createElement("script")
        script.src = "https://widget.mixcloud.com/media/js/widgetApi.js"
        script.onload = () => resolve()
        script.onerror = reject
        document.head.appendChild(script)
      })
    }
    return window.__mixcloudWidgetApiPromise
  }
}
