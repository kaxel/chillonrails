import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { page: Number, topic: String }
  static targets = ["container"]

  connect() {
    this.isLoading = false
    this.hasMore = true
    this.observer = new IntersectionObserver(this.handleIntersect.bind(this), {
      threshold: 0.1,
      rootMargin: "100px"
    })
    
    // Observe the loading indicator
    const loadingIndicator = document.getElementById("loading-indicator")
    if (loadingIndicator) {
      this.observer.observe(loadingIndicator)
    }
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  handleIntersect(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting && !this.isLoading && this.hasMore) {
        this.loadMore()
      }
    })
  }

  async loadMore() {
    if (this.isLoading) return
    
    this.isLoading = true
    this.pageValue += 1
    
    // Show loading indicator
    const loadingIndicator = document.getElementById("loading-indicator")
    if (loadingIndicator) {
      loadingIndicator.classList.remove("hidden")
    }

    try {
      const url = new URL(window.location.href)
      url.searchParams.set("page", this.pageValue)
      if (this.topicValue) {
        url.searchParams.set("topic", this.topicValue)
      }

      const response = await fetch(url, {
        headers: {
          "Accept": "text/vnd.turbo-stream.html",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (response.ok) {
        const html = await response.text()
        if (html.trim().includes('No more posts to load')) {
          this.hasMore = false
          if (loadingIndicator) {
            loadingIndicator.innerHTML = '<p class="text-gray-600">No more posts to load</p>'
            loadingIndicator.classList.remove("hidden")
          }
        } else {
          // Let Turbo handle the stream response
          Turbo.renderStreamMessage(html)
        }
      }
    } catch (error) {
      console.error("Failed to load more posts:", error)
      if (loadingIndicator) {
        loadingIndicator.classList.add("hidden")
      }
    } finally {
      this.isLoading = false
    }
  }
}