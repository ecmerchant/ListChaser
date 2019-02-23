class AddReportIdsToAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :accounts, :listing_report_id, :string
    add_column :accounts, :inventory_report_id, :string
    add_column :accounts, :listing_uploaded_at, :datetime
    add_column :accounts, :inventory_uploaded_at, :datetime
  end
end
