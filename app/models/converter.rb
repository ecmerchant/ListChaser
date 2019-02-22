class Converter < ApplicationRecord
  belongs_to :product, primary_key: 'product_id', optional: true
  has_many :items, primary_key: 'keyword', foreign_key: 'keyword'
end
