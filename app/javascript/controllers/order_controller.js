import { Controller } from "@hotwired/stimulus"
import { flashNotice, flashError } from "../shopify_app/flash_messages"

// Connects to data-controller="order"
export default class extends Controller {
  connect() {
    console.log("connected to Order controller")
  }

  return (e) {
    console.log(this.element.dataset.orderId)
    if(this.element.dataset.orderId) {
      open(`shopify://admin/orders/${this.element.dataset.orderId}`, '_top');
    } else {
      open("shopify://admin/orders", '_top');
    }
  }
}

