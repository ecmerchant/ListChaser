class Product < ApplicationRecord
  has_one :converter, primary_key: 'product_id'
  has_many :items, through: :converter
  require 'peddler'

  def self.search(user, query, type)
    account = Account.find_by(user: user)
    asin_list = Array.new
    if account == nil then return end
    marketplace = "A1VC38T7YXB528"
    client = MWS.products(
      marketplace: marketplace,
      merchant_id: account.seller_id,
      aws_access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      auth_token: account.mws_auth_token
    )
    product_list = Array.new
    converter_list = Array.new
    list = Array.new
    checker = Hash.new
    if type == 'jan' then
      query.each_slice(5) do |buf|
        response = client.get_matching_product_for_id(marketplace, "JAN", buf)
        parser = response.parse

        parser.each do |product|
          if product.class == Hash then
            input = product.dig('Id')
            temp = product.dig('Products', 'Product')
            if temp.class == Array then
              asin = product.dig('Products', 'Product', 0, 'Identifiers', 'MarketplaceASIN', 'ASIN')
              buf = product.dig('Products', 'Product', 0, 'AttributeSets', 'ItemAttributes')
              if buf != nil then
                title = buf.dig('Title')
                image = buf.dig('SmallImage', 'URL')
              else
                title = "データなし"
                image = nil
              end
            else
              asin = product.dig('Products', 'Product', 'Identifiers', 'MarketplaceASIN', 'ASIN')
              buf = product.dig('Products', 'Product', 'AttributeSets', 'ItemAttributes')
              if buf != nil then
                title = buf.dig('Title')
                image = buf.dig('SmallImage', 'URL')
              else
                title = "データなし"
                image = nil
              end
            end
          elsif product.class == Array then
            input = parser.dig('Id')
            temp = product.dig(1, 'Product')
            if temp.class == Array then
              asin = product.dig(1, 'Product', 0, 'Identifiers', 'MarketplaceASIN', 'ASIN')
              buf = product.dig(1, 'Product', 0, 'AttributeSets', 'ItemAttributes')
              if buf != nil then
                title = buf.dig('Title')
                image = buf.dig('SmallImage', 'URL')
              else
                title = "データなし"
                image = nil
              end
              break
            else
              asin = product.dig(1, 'Product', 'Identifiers', 'MarketplaceASIN', 'ASIN')
              buf = product.dig(1, 'Product', 'AttributeSets', 'ItemAttributes')
              if buf != nil then
                title = buf.dig('Title')
                image = buf.dig('SmallImage', 'URL')
              else
                title = "データなし"
                image = nil
              end
              break
            end
          end
          logger.debug(input)
          logger.debug(asin)
          logger.debug(title)

          converter_list << Converter.new({keyword: input, key_type: 'jan', product_id: asin})

          if checker.key?(asin) == false then
            url = 'https://www.amazon.co.jp/dp/' + asin.to_s
            product_list << Product.new({product_id: asin, name: title, image: image, url: url})
            checker[asin] = name
            asin_list.push(asin)
          end
        end

        Converter.import converter_list, on_duplicate_key_ignore: {constraint_name: :for_upsert_converters}
        Product.import product_list, on_duplicate_key_update: {constraint_name: :for_upsert_products, columns:[:name, :image]}

        #最安値の取得
        condition = "New"
        asin_list.each_slice(20) do |asins|

          product_list = Array.new
          response = client.get_lowest_offer_listings_for_asin(marketplace, asins, {item_condition: condition})
          parser = response.parse

          parser.each do |product|
            if product.class == Hash then
              asin = product.dig('Product', 'Identifiers', 'MarketplaceASIN', 'ASIN')
              buf = product.dig('Product', 'LowestOfferListings', 'LowestOfferListing')
              lowestprice = 0
              lowestship = 0
              lowestpoint = 0
              jp_stock = false
              if buf.class == Array then
                buf.each do |listing|
                  if listing.class == Hash then
                    fullfillment = listing.dig('Qualifiers', 'FulfillmentChannel')
                    domestic = listing.dig('Qualifiers', 'ShipsDomestically')
                    shipping = listing.dig('Qualifiers', 'ShippingTime')
                    if fullfillment == "Amazon" && domestic == "True" && shipping["Max"] == "0-2 days" then
                      if condition == "New" then
                        lowestprice = listing.dig('Price', 'ListingPrice','Amount')
                        lowestship = listing.dig('Price', 'Shipping','Amount')
                        lowestpoint = listing.dig('Price', 'Points','PointsNumber')
                        jp_stock = true
                        break
                      else
                        subcondition = listing.dig('Qualifiers', 'ItemSubcondition')
                        if subcondition == "Mint" || subcondition == "VeryGood" then
                          lowestprice = listing.dig('Price', 'ListingPrice','Amount')
                          lowestship = listing.dig('Price', 'Shipping','Amount')
                          lowestpoint = listing.dig('Price', 'Points','PointsNumber')
                          jp_stock = true
                          break
                        end
                      end
                    end
                  end
                end
              elsif buf.class == Hash
                listing = buf
                fullfillment = listing.dig('Qualifiers', 'FulfillmentChannel')
                domestic = listing.dig('Qualifiers', 'ShipsDomestically')
                shipping = listing.dig('Qualifiers', 'ShippingTime')
                if fullfillment == "Amazon" && domestic == "True" && shipping["Max"] == "0-2 days" then
                  if condition == "New" then
                    lowestprice = listing.dig('Price', 'ListingPrice','Amount')
                    lowestship = listing.dig('Price', 'Shipping','Amount')
                    lowestpoint = listing.dig('Price', 'Points','PointsNumber')
                    jp_stock = true
                  else
                    subcondition = listing.dig('Qualifiers', 'ItemSubcondition')
                    if subcondition == "Mint" || subcondition == "VeryGood" then
                      lowestprice = listing.dig('Price', 'ListingPrice','Amount')
                      lowestship = listing.dig('Price', 'Shipping','Amount')
                      lowestpoint = listing.dig('Price', 'Points','PointsNumber')
                      jp_stock = true
                    end
                  end
                end
              else
                lowestprice = 0
                lowestship = 0
                lowestpoint = 0
                jp_stock = false
              end
            else
              begin
                asin = product.dig(1, 'Identifiers', 'MarketplaceASIN', 'ASIN')
                buf = product.dig(1, 'LowestOfferListings', 'LowestOfferListing')
                lowestprice = 0
                lowestship = 0
                lowestpoint = 0
                jp_stock = false
                if buf.class == Array then
                  buf.each do |listing|
                    if listing.class == Hash then
                      fullfillment = listing.dig('Qualifiers', 'FulfillmentChannel')
                      domestic = listing.dig('Qualifiers', 'ShipsDomestically')
                      shipping = listing.dig('Qualifiers', 'ShippingTime')

                      if fullfillment == "Amazon" && domestic == "True" && shipping["Max"] == "0-2 days" then
                        if condition == "New" then
                          lowestprice = listing.dig('Price', 'ListingPrice','Amount')
                          lowestship = listing.dig('Price', 'Shipping','Amount')
                          lowestpoint = listing.dig('Price', 'Points','PointsNumber')
                          jp_stock = true
                          break
                        else
                          subcondition = listing.dig('Qualifiers', 'ItemSubcondition')
                          if subcondition == "Mint" || subcondition == "VeryGood" then
                            lowestprice = listing.dig('Price', 'ListingPrice','Amount')
                            lowestship = listing.dig('Price', 'Shipping','Amount')
                            lowestpoint = listing.dig('Price', 'Points','PointsNumber')
                            jp_stock = true
                            break
                          end
                        end
                      end
                    end
                  end
                elsif buf.class == Hash
                  listing = buf
                  fullfillment = listing.dig('Qualifiers', 'FulfillmentChannel')
                  domestic = listing.dig('Qualifiers', 'ShipsDomestically')
                  shipping = listing.dig('Qualifiers', 'ShippingTime')
                  if fullfillment == "Amazon" && domestic == "True" && shipping["Max"] == "0-2 days" then
                    if condition == "New" then
                      lowestprice = listing.dig('Price', 'ListingPrice','Amount')
                      lowestship = listing.dig('Price', 'Shipping','Amount')
                      lowestpoint = listing.dig('Price', 'Points','PointsNumber')
                      jp_stock = true
                    else
                      subcondition = listing.dig('Qualifiers', 'ItemSubcondition')
                      if subcondition == "Mint" || subcondition == "VeryGood" then
                        lowestprice = listing.dig('Price', 'ListingPrice','Amount')
                        lowestship = listing.dig('Price', 'Shipping','Amount')
                        lowestpoint = listing.dig('Price', 'Points','PointsNumber')
                        jp_stock = true
                      end
                    end
                  end
                else
                  lowestprice = 0
                  lowestship = 0
                  lowestpoint = 0
                  jp_stock = false
                end
              rescue => e
              end
            end

            if asin != nil then
              product_list << Product.new({product_id: asin, new_price: lowestprice.to_i, new_shipping: lowestship.to_i, new_point: lowestpoint.to_i})
            end
          end
          Product.import product_list, on_duplicate_key_update: {constraint_name: :for_upsert_products, columns:[:new_price, :new_shipping, :new_point]}
        end

      end
    end
  end

end
