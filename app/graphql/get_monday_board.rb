class GetMondayBoard
  include ShopifyGraphql::Query

  QUERY = <<~GRAPHQL
    query {
      boards(state: active, limit: 200) {
        name
        type
        id
      }    
    }
  GRAPHQL

  def call(name:)
    body = {query: QUERY}
    response = HTTParty.post("https://api.monday.com/v2", {
      headers: {
        "Content-Type": "application/json",
        Authorization: Rails.application.credentials.dig(:monday, :access_key_id),
        "API-version": "2024-01"
      },
      body: body.to_json
    })
    parse_data(data: response["data"]["boards"], name: name)
  end

  def parse_data(data:, name:)
    puts data.inspect
    id = ""
    rx = Regexp.new(name)
    data.each do |board|
      id = board["id"] if board["name"] =~ rx && board["type"] == "board"
    end
    id
  end
end
# {"name":"Resistor Dev","type":"board","id":"6011889795"},{"name":"MyTasks","type":"board","id":"5909041240"}
