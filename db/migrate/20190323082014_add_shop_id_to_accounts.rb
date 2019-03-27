class AddShopIdToAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :accounts, :shop_id, :string, default: "1"
  end
end
