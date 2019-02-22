class AddProfitToLists < ActiveRecord::Migration[5.2]
  def change
    add_column :lists, :profit, :integer
  end
end
