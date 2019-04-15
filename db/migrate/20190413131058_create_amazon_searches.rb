class CreateAmazonSearches < ActiveRecord::Migration[5.2]
  def change
    create_table :amazon_searches do |t|
      t.string :user
      t.text :ng_keyword

      t.timestamps
    end
  end
end
