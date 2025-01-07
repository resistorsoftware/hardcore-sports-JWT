import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  navigate(event) {
    event.preventDefault()

    const url = new URL(event.currentTarget.href)
    if (shopify) {
      url.searchParams.set('shop', shopify.config.shop)
      url.searchParams.set('host', shopify.config.host)
    }

    console.log('[shopify_app] Redirecting to:', url.toString())
    history.pushState(null, '', url.toString())
    Turbo.visit(url)
  }
}
