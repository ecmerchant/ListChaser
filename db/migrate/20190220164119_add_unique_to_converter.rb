class AddUniqueToConverter < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      ALTER TABLE converters
        ADD CONSTRAINT for_upsert_converters UNIQUE ("original_key", "product_id");
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE converters
        DROP CONSTRAINT for_upsert_converters;
    SQL
  end
end
