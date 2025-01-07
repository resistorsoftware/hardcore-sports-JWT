
# Example
#  GetBoardGroup.call(id: 6011889795, title: "Resistor Dev WIP")

class GetBoardGroup
  include ShopifyGraphql::Query

  QUERY = <<~GRAPHQL
    query($id: [ID!]) {
      boards(ids: $id) {
        groups {
    	    title
          id
        }
      }    
    }
  GRAPHQL

  def call(id:, title:)
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
    parse_data(data: response["data"]["boards"].first, title: title)
  end

  def parse_data(data:, title:)
    puts data.inspect
    id = ""
    data["groups"].each do |group|
      id = group["id"] if group["title"] == title
    end
    id
  end
end
