
require "openssl"
require "base64"

module ShopifyApp
  module Orders
    extend ActiveSupport::Concern

    def decode_monday_code(order_id:, code:)
      shopify_domain = Rails.env.development? ? "hotwire-resistor.myshopify.com" : "hardcoresport.myshopify.com"
      shop = Shop.find_by(shopify_domain: shopify_domain)
      raise "Shop not found" if shop.nil?

      order = shop.orders.find_by(order_id: order_id)
      raise "Order not found" if order.nil?

      cipher = OpenSSL::Cipher.new "aes-256-cbc"
      cipher.decrypt
      cipher.key = Base64.decode64(order.salt)
      cipher.iv = Base64.decode64(order.iv)
      # Now decrypt the data:
      decrypted = cipher.update(Base64.urlsafe_decode64(code)) + cipher.final
      logger.info "decrypted document: #{decrypted}"
      decrypted
    rescue => e
      puts "Decryption error: #{e.message}"
    end

    def size_bins(options:)
      bins = {}
      sizes = options.find { |x| x.name.downcase == "size" }
      return bins if sizes.nil?
      sizes.values.each do |size|
        bins[size.to_s] = 0
      end
      bins
    end

    def max_bins(products:)
      max_bins = 0
      products.keys.each do |k|
        if products[k]["size_bins"].keys.count > max_bins
          max_bins = products[k]["size_bins"].keys.count
        end
      end
      max_bins
    end
  end
end
