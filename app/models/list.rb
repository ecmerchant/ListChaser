class List < ApplicationRecord
  belongs_to :item, primary_key: 'item_id', optional: true
  belongs_to :product, primary_key: 'product_id', optional: true
end
