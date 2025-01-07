export function flashNotice(message) {
  if (typeof shopify === 'undefined') return

  shopify.toast.show(message)
}

export function flashError(message) {
  if (typeof shopify === 'undefined') return

  shopify.toast.show(message, { isError: true })
}
