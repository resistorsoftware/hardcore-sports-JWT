
class GetDefaultLocation
  include ShopifyGraphql::Query

  QUERY = <<~GRAPHQL
    query {
      location {
        id
        name
        address {
          phone
          formatted
        }
      }
    }
  GRAPHQL

  def call
    response = execute(QUERY)
    response.data = parse_data(response.data.location)
    response
  end

  private

  def parse_data(data)
    return {} if data.blank?

    OpenStruct.new(
      id: data.id,
      name: data.name,
      address: data.address.formatted,
      phone: data.address.phone
    )
  end
end
