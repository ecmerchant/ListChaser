class AddShopIdToLists < ActiveRecord::Migration[5.2]
  def change
    add_column :lists, :shop_id, :string
  end
end
