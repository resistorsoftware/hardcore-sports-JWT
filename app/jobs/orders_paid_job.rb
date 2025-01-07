
class OrdersPaidJob < ActiveJob::Base
  extend ShopifyAPI::Webhooks::Handler
  attr_reader :shop

  class << self
    def handle(topic:, shop:, body:)
      perform_later(topic:, shop_domain: shop, webhook: body)
    end
  end

  def perform(topic:, shop_domain:, webhook:)
    @shop = Shop.find_by(shopify_domain: shop_domain)
    hxcs_board_id = ""
    raise "No Shop record found for #{shop_domain}..." if shop.nil?

    Rails.logger.info("Orders/Paid: #{shop_domain}, #{webhook["id"]}")
    if shop.orders.find_by(order_id: webhook["id"]).nil?
      shop.orders.create(order_id: webhook["id"])
    else
      logger.info("Order already exists: #{webhook["id"]}")
      return
    end
    shop.with_shopify_session do
      default_location = GetDefaultLocation.call.data
      monday = false
      total_items = 0
      webhook["line_items"].each do |item|
        next if !item["variant_id"] && !item["product_id"]

        next if item["gift_card"] == true
        variant = GetProductVariant.call(id: "gid://shopify/ProductVariant/#{item["variant_id"]}", location_id: default_location.id).data
        # August 3rd, 2023
        # Deal with either the variant image, or the product featured image as a file to the create item call
        image = if variant.variant_image
          variant.variant_image
        elsif variant.featured_image
          variant.featured_image
        else
          ""   # this could be a universal "no Image" if needed
        end
        if variant.tags.find { |x| x.downcase == "vendor:equipe" }
          logger.info("HXCS item sold for Monday #{variant.title}")
          total_items += item["quantity"].to_i
          hxcs_board_id = GetMondayBoard.call(name: "HARDCORESPORT").to_i
          logger.info("HXCS board id: #{hxcs_board_id}")
          monday = true
        end
      rescue PG::UniqueViolation, ActiveRecord::RecordNotUnique
      rescue => e
        logger.error "Line Item processing issue: #{item.inspect}, #{e.message}"
      end
      if monday
        url_code = create_monday_code(order_id: webhook["id"])
        url = "https://hxc-monday-21440f1fb993.herokuapp.com/orders?id=#{webhook["id"]}&code=#{url_code}"
        CreateMondayItem.call(board_id: hxcs_board_id, group_id: "topics", item_name: webhook["name"], column_values: {total_units: total_items, link: {url: url, text: "Cut Sheet"}})
        logger.info("Monday Order #{webhook["name"]}, #{webhook["id"]} for #{shop_domain}, url_code: #{url_code}")
      else
        logger.info("Not a Monday order: #{webhook["name"]} for #{shop_domain}, no vendor:equipe tagged products")
      end
    end
  rescue => e
    logger.error("Orders/Paid error: #{e.message} #{e.backtrace}")
  end

  private

  def create_monday_code(order_id:)
    cipher = OpenSSL::Cipher.new "aes-256-cbc"
    cipher.encrypt
    key = cipher.random_key
    iv = cipher.random_iv
    order = shop.orders.find_by(order_id: order_id)
    raise "Oops, no order found in DB for this order: #{order_id}" if order.nil?

    order.iv = Base64.encode64(iv)
    order.salt = Base64.encode64(key)
    order.save

    # Now encrypt the data:
    document = {
      shop: shop.shopify_domain, order_id: order_id
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
