class AddShopifyHostToShops < ActiveRecord::Migration[7.0]
  def change
    add_column :shops, :shopify_host, :string
  end
end
