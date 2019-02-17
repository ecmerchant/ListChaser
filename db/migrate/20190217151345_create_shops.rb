class CreateShops < ActiveRecord::Migration[5.2]
  def change
    create_table :shops do |t|
      t.integer :shop_id
      t.text :name
      t.string :root

      t.timestamps
    end
  end
end
