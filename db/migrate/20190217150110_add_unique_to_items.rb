class AddUniqueToItems < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      ALTER TABLE items
        ADD CONSTRAINT for_upsert_items UNIQUE ("item_id");
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE items
        DROP CONSTRAINT for_upsert_items;
    SQL
  end
end
