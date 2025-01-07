import { hideProgressBar } from "./progress_bar"
import { flashError } from "./flash_messages"

document.addEventListener("DOMContentLoaded", () => {
  const shopifyAppInit = document.getElementById("shopify-app-init")
  const data = shopifyAppInit.dataset
  if (data.forceIframe === "false") { return }
  saveJwtExpireAt(data.jwtExpireAt)
  window.sessionToken = data.idToken
  window.shopifySessionId = data.sessionId

  // Append Shopify"s JWT to every Turbo request
  document.addEventListener("turbo:before-fetch-request", async (event) => {
    event.preventDefault()
    window.sessionToken = await retrieveToken()
    event.detail.fetchOptions.headers["Authorization"] = `Bearer ${window.sessionToken}`
    event.detail.fetchOptions.headers["X-Shopify-Session-Id"] = window.shopifySessionId
    event.detail.resume()
  })

  document.addEventListener("turbo:before-fetch-response", async (event) => {
    const response = event.detail.fetchResponse
    const status = response.statusCode

    window.shopifySessionId = response.header("X-Shopify-Session-Id")

    if (status == 401) {
      // Invalid token, reload token and show error
      event.preventDefault()
      hideProgressBar()
      window.sessionToken = await retrieveToken()
      window.jwtExpireAt = null
      flashError("Request failed. Please try again.")
    } else if (status == 500) {
      event.preventDefault()
      hideProgressBar()
      flashError("Server error. Please try again later.")
    } else {
      saveJwtExpireAt(response.header("X-JWT-Expire-At"))
    }
  })
})

function saveJwtExpireAt(jwtExpireAt) {
  if (jwtExpireAt && jwtExpireAt.length > 0) {
    // Convert jwtExpireAt to milliseconds
    window.jwtExpireAt = parseInt(jwtExpireAt) * 1000
  }
}

export async function retrieveToken() {
  if (window.sessionToken && window.jwtExpireAt && window.jwtExpireAt > Date.now()) {
    const diff = parseInt((window.jwtExpireAt - Date.now()) / 1000) + "s"
    console.log("[shopify_app] Reusing token. Expires in:", diff)
    return window.sessionToken
  } else {
    console.log("[shopify_app] Get new token")
    return await shopify.idToken()
  }
}
