import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { target: String }

  open(event) {
    event.preventDefault()

    const element = document.querySelector(event.params.target)
    const modal = this.application.getControllerForElementAndIdentifier(element, "modal")
    modal.open()
  }
}
