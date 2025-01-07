
# Hardcore Sport is:  5731880328
# Resistor Dev Board: https://equipeathletics.monday.com/boards/6011889795
require "openssl"
require "base64"

HXCS_ID = 5731880328

TEST_QUERY = <<~GRAPHQL
  query { 
    boards(ids: 6011889795) {
      id
      name
      items_page(limit: 4) {
        cursor
        items {
          id 
          name
          column_values {
            type
            text
            value
          }
        }
      } 
    }
  }
GRAPHQL

# {"boards"=>
#     [{"columns"=>
#        [{"id"=>"name", "title"=>"Name"},
#         {"id"=>"person", "title"=>"Person"},
#         {"id"=>"cut_ticket", "title"=>"FILES"},
#         {"id"=>"team", "title"=>"DESIGN"},
#         {"id"=>"total_units", "title"=>"Total Units"},
#         {"id"=>"date4", "title"=>"DUE"},
#         {"id"=>"subitems", "title"=>"Subitems"},
#         {"id"=>"nest", "title"=>"NEST"},
#         {"id"=>"print", "title"=>"Print"},
#         {"id"=>"cut", "title"=>"Cut"},
#         {"id"=>"sew", "title"=>"Sew"},
#         {"id"=>"date__packed", "title"=>"Date Fulfilled"},
#         {"id"=>"creation_log", "title"=>"Creation Log"}]}]},
# "account_id"=>4568459}
COLUMN_QUERY = <<~GRAPHQL
  query { 
    boards(ids: 5731880328) {
      columns {
        id
        title
      }
    }
  }
GRAPHQL

# note that for this board, the column_ids will be:
# "text4": "JUN 27"
# "numbers7": "1"
# "text": "29678"
ITEMS_QUERY = <<~GRAPHQL
  query {
    items_by_column_values(board_id: 5731880328) {
      id
      name
    }
  }
GRAPHQL

# come to live with an order id for some store
class Hardcore
  attr_reader :shop

  def initialize(order_id:)
    @shop = Shop.first
    shop.orders.find_or_create_by(order_id: order_id)
  end

  def create_monday_code(order_id:)
    cipher = OpenSSL::Cipher.new "aes-256-cbc"
    cipher.encrypt
    key = cipher.random_key
    iv = cipher.random_iv
    puts shop.shopify_domain
    order = shop.orders.find_by(order_id: order_id)
    raise "Oops, no order found in DB for this order: #{order_id}" if order.nil?

    order.iv = Base64.encode64(iv)
    order.salt = Base64.encode64(key)
    order.save

    # Now encrypt the data:
    document = {
      shop: shop.shopify_domain, order_id: order_id
    }.to_json
    puts "Original document is: #{document}"
    encrypted = cipher.update(document) + cipher.final
    puts "encrypted document: #{encrypted}"
    final_code = Base64.urlsafe_encode64(encrypted)
    puts "URL Code: #{final_code}"
    final_code
  rescue => e
    puts "Encryption test problem: #{e.message}"
  end

  def decode_monday_code(order_id:, code:)
    order = shop.orders.find_by(order_id: order_id)
    raise "Order not found" if order.nil?

    cipher = OpenSSL::Cipher.new "aes-256-cbc"
    cipher.decrypt
    cipher.key = Base64.decode64(order.salt)
    cipher.iv = Base64.decode64(order.iv)
    # Now decrypt the data:
    decrypted = cipher.update(Base64.urlsafe_decode64(code)) + cipher.final
    puts "decrypted document: #{decrypted}"
    decrypted
  rescue => e
    puts "Decryption error: #{e.message}"
  end
end

namespace :monday do
  desc "Test out order encryption"
  task encryption: :environment do
    hc = Hardcore.new
    code = hc.create_monday_code(order_id: 5603995877603)
    puts "Encrypted code sent to Monday would be: #{code}"
    result = hc.decode_monday_code(order_id: 5603995877603, code: code)
    puts "Decrypted code from Monday tells us the following: #{result}"
  end

  desc "Test monday connections"
  task test: :environment do
    puts "Testing monday connections"
    key = Rails.application.credentials.dig(:monday, :access_key_id)
    puts "API Key: #{key}"
    pp HTTParty.post("https://api.monday.com/v2", {
      headers: {
        "Content-Type": "application/json",
        Authorization: key,
        "API-version": "2024-01"
      },
      query: {query: COLUMN_QUERY}
    })
  end

  desc "add a test item to board"
  task :item, [:id] => :environment do |_, args|
    # https://admin.shopify.com/store/hotwire-resistor/orders/5820262383871
    # url = "https://hxc-monday-21440f1fb993.herokuapp.com/orders/#{args[:id]}"
    # url_code = create_monday_code(order_id: params[:id])
    # url = "https://hxc-monday-21440f1fb993.herokuapp.com/orders?id=#{params[:id]}&code=#{url_code}"
    # CreateMondayItem.call(board_id: hxcs_board_id, group_id: "topics", item_name: order.name, column_values: {total_units: @total_items, link: {url: url, text: "Cut Sheet"}})
    # current_shop.orders.create(order_id: params[:id])
    hc = Hardcore.new(order_id: args[:id])

    code = hc.create_monday_code(order_id: args[:id])
    url = "https://hxcs-monday.ngrok.io/orders?id=#{args[:id]}&code=#{code}"
    payload = {
      
    }
    CreateMondayItem.call(board_id: 6011889795,
      group_id: "topics",
      item_name: "Test Order #3",
      column_values: {total_units: 1, link: {url: url, text: "Cut Sheet"}}
    )
    puts "Order sent to Monday and Resistor Dev Board"
  end
end
