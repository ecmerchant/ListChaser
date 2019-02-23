class AddPricesToLists < ActiveRecord::Migration[5.2]
  def change
    add_column :lists, :price, :integer
    add_column :lists, :point, :integer
    add_column :lists, :condition, :string
  end
end
