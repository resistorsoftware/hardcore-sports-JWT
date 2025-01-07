# frozen_string_literal: true
# Be sure to restart your server when you modify this file.

Rack::Session::Abstract::Persisted.class_eval do
  def extract_session_id(request)
    sid = request.env["shopify_session_id"]
    sid ||= request.cookies[@key]
    sid
  end
end

class ActionDispatch::Session::ShopifySessionStore < ActionDispatch::Session::ActiveRecordStore
  def get_session_model(request, id)
    logger.silence do
      model = get_session_with_fallback(id)
      unless model
        shopify_session_id = request.env["shopify_session_id"]
        if shopify_session_id && shopify_session_id == id.public_id
          # Creating new session with Shopify session id
          model = session_class.new(:session_id => id.private_id, :data => {})
          model.save
        else
          id = generate_sid
          model = session_class.new(:session_id => id.private_id, :data => {})
          model.save
        end
      end
      if request.env[ENV_SESSION_OPTIONS_KEY][:id].nil?
        request.env[SESSION_RECORD_KEY] = model
      else
        request.env[SESSION_RECORD_KEY] ||= model
      end
      [model, id]
    end
  end
end

Rails.application.config.session_store(:shopify_session_store, key: '_hxc-monday')
