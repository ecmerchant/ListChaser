class CreateProducts < ActiveRecord::Migration[5.2]
  def change
    create_table :products do |t|
      t.string :product_id
      t.text :name
      t.string :image
      t.string :url
      t.integer :cart_price
      t.integer :cart_shipping
      t.integer :cart_point
      t.integer :new_price
      t.integer :new_shipping
      t.integer :new_point
      t.integer :used_price
      t.integer :used_shipping
      t.integer :used_point
      t.float :amazon_fee

      t.timestamps
    end
  end
end
