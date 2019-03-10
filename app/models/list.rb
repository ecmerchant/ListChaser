class List < ApplicationRecord
  belongs_to :item, primary_key: 'item_id', optional: true
  belongs_to :product, primary_key: 'product_id', optional: true

  require 'activerecord-import'
  require 'extension/string'
  require 'rakuten_web_service'

  def self.stock_update(user)
    lists = List.where(user: user, status: 'listing')

    lists.each do |list|
      logger.debug(list.item.shop_id)
      itemCode = list.item_id.gsub("_", ":")
      logger.debug(itemCode)
      if list.item.shop_id == 1.to_s then
        #rakuten
        RakutenWebService.configure do |c|
          c.application_id = ENV['RAKUTEN_APP_ID']
        end
        results = RakutenWebService::Ichiba::Item.search({itemCode: itemCode})


        results.each do |result|
          price = result['itemPrice']
          availability = result['availability']
          if availability == 0 then
            availability = false
          else
            availability = true
          end

          logger.debug(price)
          logger.debug(availability)

          list.item.update(
            price: price,
            availability: availability
          )

        end

      end
    end

  end

end
