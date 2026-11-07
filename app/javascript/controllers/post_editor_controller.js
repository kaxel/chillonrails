import { Controller } from "@hotwired/stimulus"

// Rich-text editor (Trix) for writing a new post's body. Trix is only loaded
// on pages that use this controller. Its output is shaped to match the HTML
// posts already use: <p> paragraphs, <h3> section headings, and embed players
// inserted as-is (the server unwraps them from Trix's attachment markup).
//
// Trix defines its custom elements on a setTimeout after the module loads, so
// configuring it right after the import still applies to the editor on the page.
export default class extends Controller {
  async connect() {
    const { default: Trix } = await import("trix")
    configure(Trix)
    this.Trix = Trix
  }

  // Toolbar "Embed" button: paste the embed code a player gives you
  // (Bandcamp, YouTube, Vimeo, Mixcloud, Spotify).
  insertEmbed(event) {
    event.preventDefault()
    const code = window.prompt("Paste the embed code (Bandcamp, YouTube, Vimeo, Mixcloud, or Spotify):")
    if (!code || !this.Trix) return

    const iframe = new DOMParser().parseFromString(code, "text/html").querySelector("iframe")
    if (!iframe) {
      window.alert("That doesn't look like embed code — it should contain an <iframe>.")
      return
    }

    const attachment = new this.Trix.Attachment({ content: iframe.outerHTML, contentType: "application/vnd.chillfiltr.embed" })
    this.element.querySelector("trix-editor").editor.insertAttachment(attachment)
  }

  // Only embeds can be attached; images in the body aren't supported yet.
  rejectFiles(event) {
    event.preventDefault()
  }
}

let configured = false

function configure(Trix) {
  if (configured) return
  configured = true

  const blocks = Trix.config.blockAttributes
  blocks.default.tagName = "p"
  blocks.default.breakOnReturn = true
  blocks.heading1.tagName = "h3"
}
