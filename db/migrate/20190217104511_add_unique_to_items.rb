class AddUniqueToItems < ActiveRecord::Migration[5.2]
  def change
    add_index  :items, [:user, :item_id], unique: true
  end
end
