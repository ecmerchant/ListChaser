class CreateConditionNotes < ActiveRecord::Migration[5.2]
  def change
    create_table :condition_notes do |t|
      t.string :user
      t.integer :number
      t.text :content
      t.string :memo

      t.timestamps
    end
  end
end
