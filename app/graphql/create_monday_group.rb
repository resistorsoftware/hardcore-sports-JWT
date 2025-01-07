
class CreateMondayGroup
  include ShopifyGraphql::Mutation

  QUERY = <<~GRAPHQL
    mutation($boardId: ID!, $groupName: String!) {
	    create_group (board_id: $boardId, group_name: $groupName) {
		    id
	    }
    }
  GRAPHQL

  def call(board_id:, group_name:)
    body = {query: QUERY,
            variables: {
              boardId: board_id,
              groupName: group_name
            }}
    HTTParty.post("https://api.monday.com/v2", {
      headers: {
        "Content-Type": "application/json",
        Authorization: Rails.application.credentials.dig(:monday, :access_key_id),
        "API-version": "2024-01"
      },
      body: body.to_json
    })
  end
end
