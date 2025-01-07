import { RequestInterceptor } from "@rails/request.js"
import { retrieveToken } from "./shopify_app"

RequestInterceptor.register(async (request) => {
  const token = await retrieveToken()
  request.addHeader("Authorization", `Bearer ${token}`)
})
