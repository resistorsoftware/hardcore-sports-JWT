class AddSubscriptionActiveToShops < ActiveRecord::Migration[7.1]
  def change
    add_column :shops, :subscription_active, :boolean, default: false, null: false
  end
end
