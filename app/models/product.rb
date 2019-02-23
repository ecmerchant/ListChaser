class Product < ApplicationRecord
  has_one :converter, primary_key: 'product_id'
  require 'peddler'

  def self.search(user, query, type)
    account = Account.find_by(user: user)
    etime = Time.zone.now
    stime = etime.ago(12.hours)
    darray = Converter.where(key_type: 'jan').where(updated_at: stime..etime).pluck(:keyword)
    query = query - darray
    logger.debug(query)
    if query[0] == nil then return end

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
    jj = Hash.new

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

          if checker.key?(asin) == false then
            url = 'https://www.amazon.co.jp/dp/' + asin.to_s
            checker[asin] = {product_id: asin, name: title, image: image, url: url}
            asin_list.push(asin)
          end

          if jj.key?(input) == false then
            converter_list << Converter.new({keyword: input, key_type: 'jan', product_id: asin})
            jj[input] = {keyword: input, key_type: 'jan', product_id: asin}
          end

        end
      end
      Converter.import converter_list, on_duplicate_key_update: {constraint_name: :for_upsert_converters, columns:[:key_type]}

      #価格情報の取得
      condition = "New"
      product_list = nil
      asin_list.each_slice(20) do |asins|
        #最低価格の取得
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
                  #if fullfillment == "Amazon" && domestic == "True" && shipping["Max"] == "0-2 days" then
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
                  #end
                end
              end
            elsif buf.class == Hash
              listing = buf
              fullfillment = listing.dig('Qualifiers', 'FulfillmentChannel')
              domestic = listing.dig('Qualifiers', 'ShipsDomestically')
              shipping = listing.dig('Qualifiers', 'ShippingTime')
              #if fullfillment == "Amazon" && domestic == "True" && shipping["Max"] == "0-2 days" then
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
              #end
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

                    #if fullfillment == "Amazon" && domestic == "True" && shipping["Max"] == "0-2 days" then
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
                    #end
                  end
                end
              elsif buf.class == Hash
                listing = buf
                fullfillment = listing.dig('Qualifiers', 'FulfillmentChannel')
                domestic = listing.dig('Qualifiers', 'ShipsDomestically')
                shipping = listing.dig('Qualifiers', 'ShippingTime')
                #if fullfillment == "Amazon" && domestic == "True" && shipping["Max"] == "0-2 days" then
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
                #end
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
            if checker.key?(asin) then
              bb = checker[asin]
              bb[:new_price] = lowestprice.to_i
              bb[:new_shipping] = lowestship.to_i
              bb[:new_point] = lowestpoint.to_i
              checker[asin] = bb
            else
              bb = Hash.new
              bb[:new_price] = lowestprice.to_i
              bb[:new_shipping] = lowestship.to_i
              bb[:new_point] = lowestpoint.to_i
              checker[asin] = bb
            end
          end
        end

        requests = Array.new
        asins.each_with_index do |tasin, index|
          prices = {
            ListingPrice: {Amount: 1000, CurrencyCode: "JPY"}
          }
          request = {
            MarketplaceId: marketplace,
            IdType: "ASIN",
            IdValue: tasin,
            PriceToEstimateFees: prices,
            Identifier: "req" + index.to_s,
            IsAmazonFulfilled: true
          }
          requests.push(request)
        end

        #手数料の取得
        response2 = client.get_my_fees_estimate(requests)
        parser2 = response2.parse

        buf = parser2.dig("FeesEstimateResultList", "FeesEstimateResult")
        j = 0
        referral_fee = 0
        buf.each do |result|
          tmp = result.dig("FeesEstimateIdentifier")
          asin = result.dig("FeesEstimateIdentifier", "IdValue")
          fees = result.dig("FeesEstimate")
          price = result.dig("FeesEstimateIdentifier", "PriceToEstimateFees", "ListingPrice", "Amount")

          if fees != nil then
            lists= fees.dig("FeeDetailList", "FeeDetail")
            tchecker = 0
            lists.each do |fee|
              feetype = fee.dig("FeeType")
              case feetype
                when "ReferralFee" then
                  referral_fee = fee.dig("FinalFee", "Amount")
                  tchecker += 1
                when "VariableClosingFee" then
                  tchecker += 1
              end
              if tchecker == 2 then break end
            end
          end

          if referral_fee.to_f != 0 then
            if referral_fee.to_f > 1.0 && referral_fee.to_f < price.to_f then
              rate = (referral_fee.to_f / price.to_f).round(2)
            else
              rate = 0.15
            end
          else
            rate = 0.15
          end

          if price.to_f == 0 then
            rate = 0.15
          end

          if asin != nil then
            if checker.key?(asin) then
              bb = checker[asin]
              bb[:amazon_fee] = rate
              checker[asin] = bb
            else
              bb = Hash.new
              bb[:amazon_fee] = rate
              checker[asin] = bb
            end
          end

        end
      end
      product_list = Array.new
      target = Hash[*checker.first]

      if target.values[0] != nil then
        tg = target.values[0].keys
        tg.shift(1)
        checker.each  do |key, value|
          product_list << Product.new(value)
        end
        Product.import product_list, on_duplicate_key_update: {constraint_name: :for_upsert_products, columns: tg}
      end
    end
  end

  #Feed Upload
  def self.feed_upload(user, body)
    account = Account.find_by(user: user)
    if account == nil then return end
    marketplace = "A1VC38T7YXB528"

    client = MWS.feeds(
      marketplace: marketplace,
      merchant_id: account.seller_id,
      aws_access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      auth_token: account.mws_auth_token
    )

    new_body = body.encode(Encoding::Windows_31J)

    feed_type = "_POST_FLAT_FILE_LISTINGS_DATA_"
    parser = client.submit_feed(new_body, feed_type)
    doc = Nokogiri::XML(parser.body)
    submissionId = doc.xpath(".//mws:FeedSubmissionId", {"mws"=>"http://mws.amazonaws.com/doc/2009-01-01/"}).text

    process = ""
    err = 0
    while process != "_DONE_" do
      sleep(10)
      list = {feed_submission_id_list: submissionId}
      parser = client.get_feed_submission_list(list)
      doc = Nokogiri::XML(parser.body)
      process = doc.xpath(".//mws:FeedProcessingStatus", {"mws"=>"http://mws.amazonaws.com/doc/2009-01-01/"}).text
      logger.debug(process)
      err += 1
      if err > 1 then
        break
      end
    end
    generatedId = doc.xpath(".//mws:FeedSubmissionId", {"mws"=>"http://mws.amazonaws.com/doc/2009-01-01/"}).text
    logger.debug(generatedId)
    account.update(
      listing_uploaded_at: Time.now,
      listing_report_id: generatedId
    )

  end

end
