class AddProgressToAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :accounts, :current_item_num, :integer, default: 0
    add_column :accounts, :max_page, :integer, default: 10
    add_column :accounts, :max_item_num, :integer, default: 100
  end
end
