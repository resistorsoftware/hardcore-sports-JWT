ShopifyApp.configure do |config|
  config.application_name = "HCX Monday Shopify Connector"
  config.old_secret = ""

  # Consult this page for more scope options: https://shopify.dev/api/usage/access-scopes
  config.scope = "write_products, write_publications, write_draft_orders, write_orders, write_customers,read_inventory, read_locations" # Consult this page for more scope options:
  config.embedded_app = true
  config.after_authenticate_job = false
  config.shop_session_repository = "Shop"
  config.api_version = ShopifyAPI::AdminVersions::LATEST_SUPPORTED_ADMIN_VERSION
  config.reauth_on_access_scope_changes = true
  config.new_embedded_auth_strategy = false

  config.api_key = ENV.fetch('SHOPIFY_API_KEY', '').presence
  config.secret = ENV.fetch('SHOPIFY_API_SECRET', '').presence

  # You may want to charge merchants for using your app. Setting the billing configuration will cause the Authenticated
  # controller concern to check that the session is for a merchant that has an active one-time payment or subscription.
  # If no payment is found, it starts off the process and sends the merchant to a confirmation URL so that they can
  # approve the purchase.
  #
  # Learn more about billing in our documentation: https://shopify.dev/apps/billing
  #
  # NOTE: Make sure to select public distribution for your app in Shopify Partner Dashboard. Otherwise, billing will not
  # work and you'll get an error when trying to open app.
  #
  # config.billing = ShopifyApp::BillingConfiguration.new(
  #   charge_name: "My app billing charge",
  #   amount: 5,
  #   interval: ShopifyApp::BillingConfiguration::INTERVAL_EVERY_30_DAYS,
  #   currency_code: "USD", # Only supports USD for now
  # )

  if defined? Rails::Server
    raise('Missing SHOPIFY_API_KEY. See https://github.com/Shopify/shopify_app#requirements') unless config.api_key
    raise('Missing SHOPIFY_API_SECRET. See https://github.com/Shopify/shopify_app#requirements') unless config.secret
  end
  
end

Rails.application.config.after_initialize do
  if ShopifyApp.configuration.api_key.present? && ShopifyApp.configuration.secret.present?
    ShopifyAPI::Context.setup(
      api_key: ShopifyApp.configuration.api_key,
      api_secret_key: ShopifyApp.configuration.secret,
      api_version: ShopifyApp.configuration.api_version,
      host_name: URI(ENV.fetch("HOST", "")).host || "",
      scope: ShopifyApp.configuration.scope,
      is_private: !ENV.fetch("SHOPIFY_APP_PRIVATE_SHOP", "").empty?,
      is_embedded: ShopifyApp.configuration.embedded_app,
      logger: Rails.logger,
      log_level: :info,
      private_shop: ENV.fetch("SHOPIFY_APP_PRIVATE_SHOP", nil),
      user_agent_prefix: "ShopifyApp/#{ShopifyApp::VERSION}",
    )

    ShopifyApp::WebhooksManager.add_registrations
  end
end
