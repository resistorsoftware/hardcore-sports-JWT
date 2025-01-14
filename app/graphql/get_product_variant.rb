class GetProductVariant
  include ShopifyGraphql::Query
  Variant = Struct.new(:id, :legacy_resource_id, :inventory_level_id, :display_name, :variant_image, :product_id, :tags, :featured_image, :title)

  QUERY = <<~GRAPHQL
    query($id: ID!, $location_id: ID!){
      productVariant(id: $id) {
        id
        legacyResourceId
        displayName
        inventoryItem {
          inventoryLevel(locationId: $location_id) {
            id
          }
        }
        image {
          url
        }
        product {
          id
          title
          tags
          featuredMedia {
            preview {
              image {
                url
              }
            }
          }
        }
      }
    }
  GRAPHQL

  def call(id:, location_id:)
    response = execute(QUERY, id: id, location_id: location_id)
    response.data = parse_data(data: response.data.productVariant)
    response
  end

  def parse_data(data:)
    Variant.new(
      id: data.id,
      inventory_level_id: data.inventoryItem.inventoryLevel&.id,
      legacy_resource_id: data.legacyResourceId,
      display_name: data.displayName,
      variant_image: data.image&.url,
      product_id: data.product.id,
      tags: data.product.tags,
      title: data.product.title,
      featured_image: data.product.featuredMedia&.preview&.image&.url
    )
  end
end

# s = Shop.first
# s.with_shopify_session do
#   variant = GetProductVariant.call(id: "gid://shopify/ProductVariant/9822994694180").data
#   binding.pry
# end
