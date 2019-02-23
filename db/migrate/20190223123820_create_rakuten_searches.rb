class CreateRakutenSearches < ActiveRecord::Migration[5.2]
  def change
    create_table :rakuten_searches do |t|
      t.string :user
      t.text :keyword
      t.string :shop_code
      t.string :item_code
      t.string :genre_id
      t.string :tag_id
      t.string :sort
      t.integer :min_price
      t.integer :max_price
      t.text :ng_keyword
      t.integer :postage_flag

      t.timestamps
    end
  end
end
