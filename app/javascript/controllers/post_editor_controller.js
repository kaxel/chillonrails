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

    // Capture phase on the wrapper, so this runs before Trix's own handler.
    this.newParagraph = this.newParagraph.bind(this)
    this.element.addEventListener("keydown", this.newParagraph, true)
  }

  disconnect() {
    this.element.removeEventListener("keydown", this.newParagraph, true)
  }

  // In Trix, Enter in plain text only adds a line break inside the same
  // paragraph. Make it start a new <p> instead, as writers expect; Shift+Enter
  // still adds a line break (e.g. for poetry). Headings, lists, and quotes keep
  // Trix's own Enter behavior.
  newParagraph(event) {
    if (event.key !== "Enter" || event.shiftKey || event.isComposing) return
    const trix = event.target.closest("trix-editor")
    if (!trix) return

    const editor = trix.editor
    const doc = editor.getDocument()
    const { index } = doc.locationFromPosition(editor.getSelectedRange()[0])
    if (doc.getBlockAtIndex(index).getAttributes().length > 0) return

    event.preventDefault()
    editor.recordUndoEntry("New paragraph")
    const [start, end] = editor.getSelectedRange()
    if (start !== end) editor.deleteInDirection("forward")
    editor.composition.insertBlockBreak()
    // insertBlockBreak doesn't move the browser's caret; put it at the start
    // of the new paragraph so typing continues there.
    editor.setSelectedRange(start + 1)
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

    // Trix won't render an iframe inside the editor, so the editor shows a
    // labelled card; the embed code itself travels in the attachment's
    // `embed` attribute and the server puts the real player in its place.
    const attachment = new this.Trix.Attachment({
      content: embedCard(iframe),
      embed: iframe.outerHTML,
      contentType: "application/vnd.chillfiltr.embed"
    })

    // Give the player a paragraph of its own and leave the caret on a new
    // paragraph after it. (Empty paragraphs are dropped when the post is saved.)
    const trix = this.element.querySelector("trix-editor")
    const editor = trix.editor
    const [start] = editor.getSelectedRange()
    editor.composition.insertBlockBreak()
    editor.insertAttachment(attachment)
    editor.composition.insertBlockBreak()
    editor.setSelectedRange(start + 3)
    trix.focus()
  }

  // Only embeds can be attached; images in the body aren't supported yet.
  rejectFiles(event) {
    event.preventDefault()
  }
}

const EMBED_SERVICES = { bandcamp: "Bandcamp", youtube: "YouTube", vimeo: "Vimeo", mixcloud: "Mixcloud", spotify: "Spotify" }

function embedCard(iframe) {
  const src = iframe.getAttribute("src") || ""
  const service = Object.keys(EMBED_SERVICES).find((key) => src.includes(key))
  const name = service ? EMBED_SERVICES[service] : "Embedded"
  // Bandcamp puts the track/album name in a fallback link inside the iframe,
  // which the parser keeps as raw HTML text; YouTube etc. use the title.
  const fallback = new DOMParser().parseFromString(iframe.textContent, "text/html").body.textContent
  const label = (fallback || iframe.getAttribute("title") || "").trim()

  const card = document.createElement("span")
  card.className = "post-embed-card"
  card.textContent = `▶ ${name} player${label ? ` — ${label}` : ""}`
  return card.outerHTML
}

let configured = false

function configure(Trix) {
  if (configured) return
  configured = true

  const blocks = Trix.config.blockAttributes
  blocks.default.tagName = "p"
  blocks.heading1.tagName = "h3"
}
