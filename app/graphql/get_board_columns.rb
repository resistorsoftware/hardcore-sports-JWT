class GetBoardColumns
  include ShopifyGraphql::Query

  QUERY = <<~GRAPHQL
    query($id: [ID!]) {
      boards(ids: $id) {
        columns {
    	    title
          id
        }
      }    
    }
  GRAPHQL

  def call(id:)
    body = {query: QUERY,
            variables: {
              id: id
            }}
    response = HTTParty.post("https://api.monday.com/v2", {
      headers: {
        "Content-Type": "application/json",
        Authorization: Rails.application.credentials.dig(:monday, :access_key_id),
        "API-version": "2024-01"
      },
      body: body.to_json
    })
    parse_data(data: response["data"]["boards"].first)
  end

  def parse_data(data:)
    puts data.inspect
  end
end
