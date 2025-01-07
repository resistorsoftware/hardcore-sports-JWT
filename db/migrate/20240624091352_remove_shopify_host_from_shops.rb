class RemoveShopifyHostFromShops < ActiveRecord::Migration[7.1]
  def change
    remove_column :shops, :shopify_host, :string
  end
end
