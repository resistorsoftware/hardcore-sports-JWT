# frozen_string_literal: true

class AuthenticatedController < ApplicationController
  include ShopifyApp::EnsureHasSession

  attr_reader :current_shop

  before_action :set_app_bridge_headers
  before_action :set_current_shop
#  before_action :check_subscription

  helper_method :current_shop, :jwt_expire_at, :current_session_id

  def set_current_shop
    @current_shop = Shop.find_by(shopify_domain: current_shopify_domain)
  end

  def default_url_options
    { shop: current_shopify_domain, session: current_session_id }
  end

  def id_token_param
    {id_token: shopify_id_token}
  end

  private

  def current_session_id
    @current_session_id ||= params[:session].presence || request.headers['X-Shopify-Session-Id']
  end

  def set_app_bridge_headers
    if jwt_expire_at
      response.set_header('X-JWT-Expire-At', jwt_expire_at)
    end
    if current_session_id
      response.set_header('X-Shopify-Session-Id', current_session_id)
    end
  end

  def turbo_flashes
    turbo_stream.replace("shopify-app-flash", partial: "layouts/flash_messages.html.erb")
  end

  def check_subscription
    return if current_shop.subscription_active?

    redirect_to new_subscription_path(**id_token_param)
  end
end
