import { Controller } from "@hotwired/stimulus"
import { flashNotice } from "../shopify_app/flash_messages"

export default class extends Controller {
  static values = {
    type: { type: String, default: "product" }
  }

  async open(event) {
    event.preventDefault()

    const options = {
      type: this.typeValue,
      multiple: true
    }
    if (this.typeValue === 'product') {
      options['filter'] = {
        variants: false
      }
    }

    const selected = await shopify.resourcePicker(options)
    if (selected) {
      flashNotice('Selected ' + selected.length + ' ' + this.typeValue + '(s)')
    }
  }
}
