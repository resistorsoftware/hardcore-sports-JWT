require "test_helper"

Capybara.server = :puma, {Silent: true}
Capybara.default_max_wait_time = 15

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  teardown do
    clear_login
  end

  def login(shop)
    stubbed_session = ShopifyAPI::Auth::Session.new(
      shop: shop.shopify_domain,
      access_token: shop.shopify_token
    )
    ShopifyAPI::Utils::SessionUtils.stubs(:current_session_id).returns("session_id")
    ShopifyAPI::Utils::SessionUtils.stubs(:session_id_from_shopify_id_token).returns("session_id")
    ShopifyApp::SessionRepository.stubs(:load_session).returns(stubbed_session)
  end

  def clear_login
    ShopifyAPI::Utils::SessionUtils.unstub(:current_session_id)
    ShopifyAPI::Utils::SessionUtils.unstub(:session_id_from_shopify_id_token)
    ShopifyApp::SessionRepository.unstub(:load_session)
  end
end
