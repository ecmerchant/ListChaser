class List < ApplicationRecord
  belongs_to :item, primary_key: 'item_id', optional: true
end
