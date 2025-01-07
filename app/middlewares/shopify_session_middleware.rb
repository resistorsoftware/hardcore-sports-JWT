class ShopifySessionMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    sid = request.params["session"].presence
    sid ||= env["HTTP_X_SHOPIFY_SESSION_ID"].presence
    if sid
      env["shopify_session_id"] = sid
    end

    @app.call(env)
  end
end
