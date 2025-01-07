
class OrdersController < ApplicationController
  # Build in our own security for calls coming from Monday
  include ShopifyApp::Orders

  def show
    logger.info("incoming request to show off an order #{order_params}")
    @original_data = JSON.parse(decode_monday_code(order_id: order_params["id"], code: order_params["code"]))
    logger.info("Original Data: #{@original_data}, #{@original_data.class}")
    if ["hotwire-resistor.myshopify.com","hardcoresport.myshopify.com"].include?(@original_data["shop"])
    
      # Dish out the order
      shop = Shop.find_by(shopify_domain: @original_data["shop"])
      raise "Could not find shop in DB" if shop.nil?

      @items = Hash.new { |h, k| h[k] = [] }
      @products = Hash.new { |h, k| h[k] = {} }
      @sizes = Hash.new { |h, k| h[k] = {} }
      shop.with_shopify_session do
        @order = GetOrderForMonday.call(id: "gid://shopify/Order/#{@original_data["order_id"]}").data
        # go through the line items and build up the products for efficiency sake
        @order.line_items.each do |item|
          # only if the product was tagged as vendor:equipe should we have the product
          if item&.product&.tags&.include?("vendor:equipe")
            # each variant of a product sold some quantity, so we can nail that down first
            # also, all the sizes are part of the options so we can nail those down too
            size = item.variant.selected_options.find { |option| option.name.downcase == "size" }.value
            quantity = item.quantity
            if !@products.key?(item.product.id)
              # we have a new product, so we need to add it to the list, and give it some defaults
              @products[item.product.id]["size_bins"] = size_bins(options: item.product.options)
            end
            @products[item.product.id]["thread"] = item.product.thread_color
            @products[item.product.id]["lining"] = item.product.lining
            @products[item.product.id]["title"] = item.product.title
            @products[item.product.id]["size_bins"][size.to_s] += quantity
            # @items[item.product.id][size] = quantity

            @items[item.product.id] << item
          end
        end
        @max_bins = max_bins(products: @products)
        logger.info("Max Bins: #{@max_bins}, products: #{@products}")
      end
    end
    render layout: false
  rescue => e
    logger.error "Problem processing incoming order request: #{e.message}\n#{e.backtrace}"
  end

  private

  def order_params
    params.permit(:id, :code)
  end
end
