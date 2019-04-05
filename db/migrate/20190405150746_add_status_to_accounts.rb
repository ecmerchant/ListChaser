class AddStatusToAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :accounts, :progress, :string
  end
end
