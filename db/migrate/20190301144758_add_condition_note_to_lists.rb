class AddConditionNoteToLists < ActiveRecord::Migration[5.2]
  def change
    add_column :lists, :condition_note, :text
  end
end
