class CreateConverters < ActiveRecord::Migration[5.2]
  def change
    create_table :converters do |t|
      t.text :original_key
      t.string :key_type
      t.string :product_id

      t.timestamps
    end
  end
end
