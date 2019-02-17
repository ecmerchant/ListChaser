class CreateItems < ActiveRecord::Migration[5.2]
  def change
    create_table :items do |t|
      t.string :user
      t.string :item_id
      t.string :shop_id
      t.string :url
      t.text :name
      t.string :jan
      t.string :mpn
      t.integer :price
      t.string :image
      t.text :description
      t.string :category_id
      t.text :keyword

      t.timestamps
    end
  end
end
