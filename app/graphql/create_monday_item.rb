
# The Monday boards of some interest
# {"id"=>"997119882", "name"=>"PEDAL INDUSTRIES - SOCKS"},
# {"id"=>"4094555607", "name"=>"Subitems of PEDAL INDUSTRIES - SOCKS"}
# note that for this board, the column_ids will be:
# "text4": "JUN 27"
# "numbers7": "1"
# "text": "29678"


# Example
#  CreateMondayItem.call(board_id: 6011889795, group_id: "topics", item_name: "dDave-1", column_values: { "link": { "url": "https://google.com", "text": "The Goog"}})
require "open-uri"
require "tempfile"

class CreateMondayItem
  include ShopifyGraphql::Mutation
  QUERY = <<~GRAPHQL
    mutation($boardId: ID!, $groupId: String!, $itemName: String!, $columnValues: JSON!) {
      create_item(board_id: $boardId, group_id: $groupId, item_name: $itemName, column_values: $columnValues) {
        id
      }
    }
  GRAPHQL

  FILE_MUTATION = <<~GRAPHQL
    mutation($item_id: ID!, $file: File!) {
      add_file_to_column (item_id: $item_id, column_id: "files", file: $file) {
        id
      }
    }
  GRAPHQL

  def call(board_id:, group_id:, item_name:, column_values:)
    body = {query: QUERY,
            variables: {
              boardId: board_id,
              groupId: group_id,
              itemName: item_name.to_s,
              columnValues: JSON.dump(column_values)
            }}
    # body[:variables].merge(groupId: group_id) if !group_id.empty?

    # pp body

    result = HTTParty.post("https://api.monday.com/v2", {
      headers: {
        "Content-Type": "application/json",
        Authorization: Rails.application.credentials.dig(:monday, :access_key_id),
        "API-version": "2024-01"
      },
      body: body.to_json
    })
    pp result

    item_id = result["data"]["create_item"]["id"]
    puts "Created an item with id: #{item_id}"

    # download the image from Shopify into a file object and then send that to the Monday?
    # image_file = Tempfile.new
    # image_file.binmode
    # uri = URI(image)
    # IO.copy_stream(uri.open, image_file)
    # image_file.rewind

    # query = "mutation ($file: File!) { add_file_to_column (file: $file, item_id: #{item_id}, column_id: \"files\") { id } }"
    # boundary = "xxxxxxxxxxxxxxxxxxxxx"
    # data = ""
    # data += "--" + boundary + "\r\n"
    # data += "Content-Disposition: form-data; name=\"query\"; \r\n"
    # data += "Content-Type:application/json\r\n\r\n"
    # data += "\r\n" + query + "\r\n"
    # data += "--" + boundary + "\r\n"
    # data += "Content-Disposition: form-data; name=\"variables[file]\"; filename=\"" + image + "\"\r\n"
    # data += "Content-Type:application/octet-stream\r\n\r\n"
    # data += image_file.read
    # data += "\r\n--" + boundary + "--\r\n"
    # result = HTTParty.post("https://api.monday.com/v2/file", {
    #   headers: {
    #     "Content-Type": "multipart/form-data; boundary=" + boundary,
    #     Authorization: Rails.application.credentials.dig(:monday, :access_key_id),
    #     "API-version": "2023-04"
    #   },
    #   body: data
    # })
    # pp result
  end
end
