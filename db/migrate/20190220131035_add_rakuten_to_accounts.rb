class AddRakutenToAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :accounts, :rakuten_app_id, :string
  end
end
