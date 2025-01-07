import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  show(event) {
    if (this.confirmed) return

    event.preventDefault()

    const modalElement = document.querySelector(event.params.target)
    const modal = this.application.getControllerForElementAndIdentifier(modalElement, "modal")
    modal.open()

    window.activeConfirmation = this
  }

  confirm() {
    this.confirmed = true
    this.element.click()
  }
}
