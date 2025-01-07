window.progressBarDelay = 300 // milliseconds
window.progressBarVisible = false
window.progressBarTimeout = null

export function showProgressBar() {
  if (progressBarVisible) return
  shopify.loading(true)
  progressBarVisible = true
}

export function hideProgressBar() {
  clearTimeout(progressBarTimeout)
  shopify.loading(false)
  progressBarVisible = false
}

document.addEventListener("turbo:before-visit", () => {
  progressBarTimeout = setTimeout(showProgressBar, progressBarDelay)
})
document.addEventListener("turbo:load", () => {
  hideProgressBar()
})
