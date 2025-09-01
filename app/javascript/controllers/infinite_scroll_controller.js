import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { page: Number, topic: String }

  connect() {
    console.log("Infinite scroll controller connected", { page: this.pageValue, topic: this.topicValue })
    this.isLoading = false
    this.hasMore = true
    
    this.setupIntersectionObserver()
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  setupIntersectionObserver() {
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting && !this.isLoading && this.hasMore) {
          console.log("Loading more posts...")
          this.loadMore()
        }
      })
    }, {
      threshold: 0.1,
      rootMargin: "100px"
    })
    
    // Observe the loading indicator
    const loadingIndicator = document.getElementById("loading-indicator")
    if (loadingIndicator) {
      this.observer.observe(loadingIndicator)
      console.log("Observing loading indicator")
    } else {
      console.error("Loading indicator not found")
    }
  }

  async loadMore() {
    if (this.isLoading) {
      console.log("Already loading, skipping...")
      return
    }
    
    this.isLoading = true
    this.pageValue += 1
    
    console.log("Loading page", this.pageValue)
    
    // Show loading indicator
    const loadingIndicator = document.getElementById("loading-indicator")
    if (loadingIndicator) {
      loadingIndicator.classList.remove("hidden")
    }

    try {
      const url = new URL(window.location.origin + "/")
      url.searchParams.set("page", this.pageValue)
      if (this.topicValue && this.topicValue !== '') {
        url.searchParams.set("topic", this.topicValue)
      }

      console.log("Fetching:", url.toString())

      const response = await fetch(url, {
        headers: {
          "Accept": "text/vnd.turbo-stream.html"
        }
      })

      if (response.ok) {
        const html = await response.text()
        console.log("Response received:", html.substring(0, 200) + "...")
        
        if (html.trim().includes('No more posts to load')) {
          console.log("No more posts available")
          this.hasMore = false
        }
        
        // Let Turbo handle the stream response
        if (window.Turbo) {
          Turbo.renderStreamMessage(html)
        } else {
          console.error("Turbo not available")
        }
      } else {
        console.error("Response not OK:", response.status)
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