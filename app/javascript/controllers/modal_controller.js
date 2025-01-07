import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open(event) {
    if (event) event.preventDefault()
    this.element.show()
  }

  close(event) {
    if (event) event.preventDefault()
    this.element.hide()
  }

  confirm(event) {
    if (event) event.preventDefault()
    this.close()
    if (window.activeConfirmation)
      window.activeConfirmation.confirm()
  }
}
