class CreateLists < ActiveRecord::Migration[5.2]
  def change
    create_table :lists do |t|
      t.string :user
      t.string :item_id
      t.string :product_id
      t.string :status

      t.timestamps
    end
  end
end
