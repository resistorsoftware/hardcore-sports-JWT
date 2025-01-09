class OrderController < AuthenticatedController
  def index
    Rails.logger.info("Got a command to send a Shopify order to monday as if hit by a webhook, #{params}")
    hxcs_board_id = ""
    board_name = Rails.env.development? ? "Resistor Dev" : "HARDCORESPORT"
    shop_url = Rails.env.development? ? "hxcs-monday.ngrok.io" : "hxc-monday-21440f1fb993.herokuapp.com"
    current_shop.with_shopify_session do |session|
      if current_shop.orders.find_by(order_id: params[:id]).nil?
        current_shop.orders.create(order_id: params[:id])
        @order = GetOrderForMonday.call(id: "gid://shopify/Order/#{params[:id]}").data
        @monday = false
        @total_items = 0
        @sku_list = []
        @order.line_items.each do |item|
          if item.product.tags.find { |x| x.downcase == "vendor:equipe" }
            Rails.logger.info("HXCS item sold for Monday #{item.product.title}")
            @total_items += item.quantity.to_i
            @sku_list << item.sku
            hxcs_board_id = GetMondayBoard.call(name: board_name).to_i
            Rails.logger.info("HXCS board id: #{hxcs_board_id}")
            @monday = true
          end
        rescue PG::UniqueViolation, ActiveRecord::RecordNotUnique
        rescue => e
          Rails.logger.error "Line Item processing issue: #{item.inspect}, #{e.message}"
        end

        if @monday
          begin
            url_code = create_monday_code(order_id: params[:id])
            url = "https://#{shop_url}/orders?id=#{params[:id]}&code=#{url_code}"
            # December 2024, add a hoverable item to the design column that would show off all the SKUs in an order
            # the design column is accessed via the "team" ID
            column_values = {
              team: @sku_list.join(", "),
              total_units: @total_items,
              link: {
                url: url,
                text: "Cut Sheet",
                url_text: "lorem ipsum facto de facto the dog barks"
              }
            }
            CreateMondayItem.call(board_id: hxcs_board_id, group_id: "topics", item_name: @order.name, column_values: column_values)
            Rails.logger.info("Monday Order #{@order.name}, order ID: #{params[:id]} for #{current_shop.shopify_domain}, url_code: #{url_code}")
          rescue => e
            Rails.logger.error("Problem trying to send to Monday: #{e.message}, #{e.backtrace}")
          end
        else
          Rails.logger.info("Not a Monday order: #{params["name"]} for #{current_shop.shopify_domain}, no vendor:equipe tagged products")
        end
      else
        Rails.logger.info("Order already exists: #{params[:id]}")
      end
    end
  end

  private

  def create_monday_code(order_id:)
    cipher = OpenSSL::Cipher.new "aes-256-cbc"
    cipher.encrypt
    key = cipher.random_key
    iv = cipher.random_iv
    order = current_shop.orders.find_by(order_id: order_id)
    raise "Oops, no order found in DB for this order: #{order_id}" if order.nil?

    order.iv = Base64.encode64(iv)
    order.salt = Base64.encode64(key)
    order.save

    # Now encrypt the data:
    document = {
      shop: current_shop.shopify_domain, order_id: order_id
    }.to_json
    logger.info "Original document is: #{document}"
    encrypted = cipher.update(document) + cipher.final
    logger.info "encrypted document: #{encrypted}"
    final_code = Base64.urlsafe_encode64(encrypted)
    logger.info "URL Code: #{final_code}"
    final_code
  rescue => e
    logger.error "Encryption test problem: #{e.message}"
  end
end
