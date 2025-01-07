# frozen_string_literal: true
class Shop < ActiveRecord::Base
  include ShopifyApp::ShopSessionStorageWithScopes

  has_many :orders, dependent: :destroy

  def api_version
    ShopifyApp.configuration.api_version
  end

  def shop_handle
    shopify_domain.split(".myshopify.com").first
  end

  def admin_url(path = nil)
    "https://admin.shopify.com/store/#{shop_handle}#{path}"
  end
end
