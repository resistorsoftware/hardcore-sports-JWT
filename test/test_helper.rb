ENV['RAILS_ENV'] ||= 'test'
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"
require "mocha/minitest"

VCR.configure do |config|
  config.ignore_localhost = true
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
  config.allow_http_connections_when_no_cassette = true
end

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  setup do
    enable_vcr
  end

  teardown do
    disable_vcr
  end

  def enable_vcr
    absolute_test_path = method(name).source_location.first
    relative_test_path = absolute_test_path.gsub(Rails.root.to_s, "")
    vcr_path = relative_test_path.gsub(%r{^/test/}, "").gsub(%r{.rb$}, "")

    VCR.insert_cassette "#{vcr_path}/#{name}", preserve_exact_body_bytes: true
  end

  def disable_vcr
    VCR.eject_cassette
  end
end

class ActionDispatch::IntegrationTest
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
