import { Controller } from "@hotwired/stimulus"

// Drives the /support donation form: a $-increment stepper plus an inline
// Stripe card Element. Payment is confirmed in place (stripe.confirmCardPayment)
// with no redirect, so the card fields never leave this page.
export default class extends Controller {
  static targets = ["form", "amount", "cardElement", "errorMessage", "amountDue",
                     "submitButton", "spinner", "submitLabel", "successMessage"]
  static values = { increment: Number, min: Number, publishableKey: String, createIntentUrl: String }

  connect() {
    this.amountCents = this.minValue
    this.stripe = Stripe(this.publishableKeyValue)
    this.elements = this.stripe.elements()
    this.cardElement = this.elements.create("card")
    this.cardElement.mount(this.cardElementTarget)
    this.cardElement.on("change", (event) => {
      if (event.error) {
        this.showError(event.error.message)
      } else {
        this.hideError()
      }
    })
    this.updateDisplay()
  }

  increment() {
    this.amountCents += this.incrementValue
    this.updateDisplay()
  }

  decrement() {
    if (this.amountCents - this.incrementValue < this.minValue) return
    this.amountCents -= this.incrementValue
    this.updateDisplay()
  }

  updateDisplay() {
    const dollars = (this.amountCents / 100).toFixed(2)
    this.amountTarget.textContent = `$${dollars}`
    this.amountDueTarget.textContent = `$${dollars}`
  }

  async submit() {
    this.setLoading(true)
    this.hideError()

    try {
      const response = await fetch(this.createIntentUrlValue, {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": this.csrfToken() },
        body: JSON.stringify({ amount_cents: this.amountCents })
      })
      const data = await response.json()
      if (data.error) {
        this.showError(data.error)
        this.setLoading(false)
        return
      }

      const { error } = await this.stripe.confirmCardPayment(data.client_secret, {
        payment_method: { card: this.cardElement }
      })

      if (error) {
        this.showError(error.message)
        this.setLoading(false)
        return
      }

      this.showSuccess()
    } catch (e) {
      this.showError("Something went wrong. Please try again.")
      this.setLoading(false)
    }
  }

  setLoading(isLoading) {
    this.submitButtonTarget.disabled = isLoading
    this.spinnerTarget.classList.toggle("hidden", !isLoading)
    this.submitLabelTarget.textContent = isLoading ? "Processing…" : "Submit"
  }

  showError(message) {
    this.errorMessageTarget.textContent = message
    this.errorMessageTarget.classList.remove("hidden")
  }

  hideError() {
    this.errorMessageTarget.classList.add("hidden")
  }

  showSuccess() {
    this.formTarget.classList.add("hidden")
    this.successMessageTarget.classList.remove("hidden")
  }

  csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}
