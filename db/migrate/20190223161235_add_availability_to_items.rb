class AddAvailabilityToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :availability, :boolean, default: true
  end
end
