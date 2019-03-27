class CreateYahooAucSearches < ActiveRecord::Migration[5.2]
  def change
    create_table :yahoo_auc_searches do |t|
      t.string :user
      t.text :search_url

      t.timestamps
    end
  end
end
