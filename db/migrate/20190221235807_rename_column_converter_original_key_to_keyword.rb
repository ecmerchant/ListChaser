class RenameColumnConverterOriginalKeyToKeyword < ActiveRecord::Migration[5.2]
  def change
    rename_column :converters, :original_key, :keyword
  end
end
