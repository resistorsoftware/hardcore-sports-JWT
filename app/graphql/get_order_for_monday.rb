class GetOrderForMonday
  include ShopifyGraphql::Query

  INITIAL_QUERY = <<~GRAPHQL
    query ($id: ID!, $cursor: String) {
      order(id: $id) {
        id
        legacyResourceId
        name
        createdAt
        shippingAddress {
          address1
          address2
          firstName
          lastName
          city
          country
          countryCodeV2
          latitude
          longitude
          name
          phone
          province
          provinceCode
          zip
        }
        lineItems(first: 5, after: $cursor) {
          pageInfo { 
            endCursor
            hasNextPage 
          }
          edges {
            node {
              id
              image {
                url
              }
              product {
                legacyResourceId
                title
                tags
                media(first: 2, query:"media_type:IMAGE") {
                  edges {
                    node {
                      preview {
                        image {
                          url
                        }
                      }
                    }
                  }     
                }
                options {
									name
									values
								}
              }
              sku
              quantity
              variantTitle
              variant {
                selectedOptions {
									name
									value
								}
                displayName
              }
            }
          }
        }
      }
    }
  GRAPHQL

  LINEITEMS_QUERY = <<~GRAPHQL
    query ($id: ID!, $cursor: String) {
      order(id: $id) {
        lineItems(first: 5, after: $cursor) {
          pageInfo { 
            endCursor
            hasNextPage 
          }
          edges {
            node {
              id
              image {
                url
              }
              product {
                legacyResourceId
                title
                tags
                media(first: 2, query:"media_type:IMAGE") {
                  edges {
                    node {
                      preview {
                        image {
                          url
                        }
                      }
                    }
                  }     
                }
                options {
									name
									values
								}
              }
              sku
              quantity
              variantTitle
              variant {
                selectedOptions {
									name
									value
								}
                displayName
              }
            }
          }
        }
      }
    }
  GRAPHQL

  def call(id:)
    Rails.logger.info("Calling GQL for order")
    response = execute(INITIAL_QUERY, id: id, cursor: nil)
    order = response.data.order
    Rails.logger.info("Initial aspect of order: #{response.inspect}")
    if order.nil?
      response.data = order
    else
      while response.data.order.lineItems.pageInfo.hasNextPage
        begin
          response = execute(LINEITEMS_QUERY, id: id, cursor: response.data.order.lineItems.pageInfo.endCursor)
          # Rails.logger.info("Variant query response: #{response.inspect}")
          order.lineItems.edges += response.data.order.lineItems.edges
        rescue ShopifyGraphql::TooManyRequests
          Rails.logger.info("Too many requests - sleep")
          sleep(5)
          retry
        end
      end
    end
    response.data = parse_data(data: order)
    response
  end

  def parse_data(data:)
    Rails.logger.info("GQL Order: #{data.inspect}")
    OpenStruct.new(
      id: data.id,
      legacy_resource_id: data.legacyResourceId,
      name: data.name,
      created_at: data.createdAt,
      shipping_address: OpenStruct.new(
        address1: data.shippingAddress&.address1,
        address2: data.shippingAddress&.address2,
        first_name: data.shippingAddress&.firstName,
        last_name: data.shippingAddress&.lastName,
        city: data.shippingAddress&.city,
        country: data.shippingAddress&.country,
        country_code_v2: data.shippingAddress&.countryCodeV2,
        name: data.shippingAddress&.name,
        phone: data.shippingAddress&.phone,
        province: data.shippingAddress&.province,
        province_code: data.shippingAddress&.provinceCode,
        zip: data.shippingAddress&.zip
      ),
      line_items: data.lineItems.edges.map do |edge|
        if edge.node.product
          OpenStruct.new(
            id: edge.node&.id,
            sku: edge.node&.sku,
            quantity: edge.node&.quantity,
            variant_title: edge.node&.variantTitle,
            variant: OpenStruct.new(
              display_name: edge.node&.variant&.displayName,
              selected_options: edge.node&.variant&.selectedOptions&.map do |option|
                OpenStruct.new(
                  name: option.name,
                  value: option.value
                )
              end
            ),
            image: OpenStruct.new(
              url: edge.node&.image&.url
            ),
            product: OpenStruct.new(
              id: edge.node&.product&.legacyResourceId,
              title: edge.node&.product&.title,
              options: edge.node&.product&.options&.map do |option|
                OpenStruct.new(
                  name: option.name,
                  values: option.values
                )
              end,
              tags: edge.node&.product&.tags,
              lining: edge.node&.product&.tags&.find { |tag| /lining/ =~ tag }&.split(":")&.last,
              thread_color: edge.node&.product&.tags&.find { |tag| /threadcolor/ =~ tag }&.split(":")&.last,
              packaging: edge.node&.product&.tags&.find { |tag| /packaging/ =~ tag }&.split(":")&.last,
              featured_image: OpenStruct.new(
                url: edge.node&.product&.featuredImage&.url
              ),
              images: edge.node&.product&.media&.edges&.map do |image|
                OpenStruct.new(
                  url: image&.node&.preview&.image&.url
                )
              end
            )
          )
        end
      end
    )
  end
end
