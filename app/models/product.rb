class Product < ApplicationRecord

  require 'peddler'

  def self.search(user, query, type)
    account = Account.find_by(user: user)
    if account == nil then return end
    marketplace = "A1VC38T7YXB528"
    client = MWS.products(
      marketplace: marketplace,
      merchant_id: account.seller_id,
      aws_access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      auth_token: account.mws_auth_token
    )
    list = Array.new
    if type == 'jan' then
      query.each_slice(5) do |buf|
        response = client.get_matching_product_for_id(marketplace, "JAN", buf)
        parser = response.parse

        parser.each do |product|
          if product.class == Hash then
            input = product.dig('Id')
            temp = product.dig('Products', 'Product')
            logger.debug(temp.class)
            if temp.class == Array then
              asin = product.dig('Products', 'Product', 0, 'Identifiers', 'MarketplaceASIN', 'ASIN')
              buf = product.dig('Products', 'Product', 0, 'AttributeSets', 'ItemAttributes')
              if buf != nil then
                title = buf.dig("Title")
              else
                title = "データなし"
              end
            else
              asin = product.dig('Products', 'Product', 'Identifiers', 'MarketplaceASIN', 'ASIN')
              buf = product.dig('Products', 'Product', 'AttributeSets', 'ItemAttributes')
              if buf != nil then
                title = buf.dig("Title")
              else
                title = "データなし"
              end
            end
          elsif product.class == Array then
            input = parser.dig('Id')
            asin = product.dig(1, 'Product', 'Identifiers', 'MarketplaceASIN', 'ASIN')
            buf = product.dig(1, 'Product', 'AttributeSets', 'ItemAttributes')
            if buf != nil then
              title = buf.dig("Title")
            else
              title = "データなし"
            end
            break
          end
          logger.debug(input)
          logger.debug(asin)
          logger.debug(title)
          list << Converter.new({original_key: input, key_type: 'jan', product_id: asin})
        end
        Converter.import list, on_duplicate_key_ignore: {constraint_name: :for_upsert_converters}
        
      end
    end
  end

end
