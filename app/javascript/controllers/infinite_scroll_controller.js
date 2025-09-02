import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { page: Number, topic: String }

  connect() {
    console.log("Infinite scroll controller connected", { page: this.pageValue, topic: this.topicValue })
    this.isLoading = false
    this.hasMore = true
    this.loadedPostIds = new Set()
    
    // Track initially loaded posts to prevent duplicates
    this.trackExistingPosts()
    this.setupIntersectionObserver()
  }
  
  trackExistingPosts() {
    // Find all existing post elements and track their IDs
    const existingPosts = document.querySelectorAll('[data-post-id]')
    existingPosts.forEach(post => {
      const postId = post.dataset.postId
      if (postId) {
        this.loadedPostIds.add(postId)
      }
    })
    console.log(`Tracked ${this.loadedPostIds.size} existing posts`)
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  setupIntersectionObserver() {
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        console.log("Intersection observer triggered", { 
          isIntersecting: entry.isIntersecting, 
          isLoading: this.isLoading, 
          hasMore: this.hasMore 
        })
        if (entry.isIntersecting && !this.isLoading && this.hasMore) {
          console.log("Loading more posts...")
          this.loadMore()
        }
      })
    }, {
      threshold: 0.1,
      rootMargin: "50px"
    })
    
    // Observe the loading indicator
    const loadingIndicator = document.getElementById("loading-indicator")
    if (loadingIndicator) {
      this.observer.observe(loadingIndicator)
      console.log("Observing loading indicator", loadingIndicator)
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
      loadingIndicator.innerHTML = `
        <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900"></div>
        <p class="mt-2 text-gray-600">Loading more posts...</p>
      `
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
        
        // Check if we got any posts back
        if (html.trim().length === 0 || html.includes('<!-- No more posts -->')) {
          console.log("No more posts available")
          this.hasMore = false
          const loadingIndicator = document.getElementById("loading-indicator")
          if (loadingIndicator) {
            loadingIndicator.innerHTML = '<p class="text-gray-600">No more posts to load</p>'
          }
        } else {
          // Let Turbo handle the stream response
          if (window.Turbo) {
            Turbo.renderStreamMessage(html)
          } else {
            console.error("Turbo not available")
          }
          // Clear loading indicator after successful load
          const loadingIndicator = document.getElementById("loading-indicator")
          if (loadingIndicator) {
            loadingIndicator.innerHTML = ""
          }
        }
      } else {
        console.error("Response not OK:", response.status)
      }
    } catch (error) {
      console.error("Failed to load more posts:", error)
      const loadingIndicator = document.getElementById("loading-indicator")
      if (loadingIndicator) {
        loadingIndicator.innerHTML = ""
      }
    } finally {
      this.isLoading = false
    }
  }
}