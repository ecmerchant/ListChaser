class Item < ApplicationRecord
  belongs_to :shop, primary_key: 'shop_id', optional: true
  belongs_to :converter, primary_key: 'keyword', foreign_key: 'keyword'

  require 'activerecord-import'
  require 'extension/string'
  require 'rakuten_web_service'

  def self.search(user, keyword, shop_id)
    logger.debug("========= SEARCH ==========")
    @account = Account.find_or_create_by(user: user)

    case shop_id
    when 1 then
      #楽天市場 API
      RakutenWebService.configure do |c|
        c.application_id = ENV['RAKUTEN_APP_ID']
      end

      results = RakutenWebService::Ichiba::Item.search(:keyword => keyword)
      item_num = results.count
      page = 0

      if item_num > 0 then
        #検索結果からアイテム取り出し
        counter = 0
        if @account.current_item_num == 0 then
          @account.update(
            max_item_num: @account.max_page
          )
        end
        res = Hash.new
        jans = []

        while results.has_next_page?
          checker = Hash.new
          item_list = Array.new
          user_list = Array.new

          results.each do |result|

            logger.debug('---------- No. ' + (counter + 1).to_s + ' -----------')
            url = result['itemUrl']
            item_id = result['itemCode'].gsub(':','_')
            image = result['mediumImageUrls'][0]
            name = result['itemName']
            price = result['itemPrice']

            code = url.gsub('https://item.rakuten.co.jp/','')
            code = /\/([\s\S]*?)\//.match(code)[1]
            logger.debug(code)
            if code.end_with?("_") then
              code.chop!
            end
            if code.jan? then
              jan = code
              jans.push(jan)
            else
              jan = nil
            end

            if jan != nil then
              keyword = jan
            else
              keyword = name
            end
            category_id = result['genreId']
            description = result['itemCaption']
            mpn = nil

            res = {
              item_id: item_id,
              name: name,
              price: price,
              image: image,
              url: url,
              jan: jan,
              mpn: mpn,
              description: description,
              category_id: category_id,
              shop_id: shop_id,
              keyword: keyword
            }
            logger.debug(item_id)

            if checker.key?(item_id) == false then
              item_list << Item.new(res)
              user_list << List.new({user: user, item_id: item_id, status: 'before_sale'})
              checker[item_id] = name
              counter += 1
            end
            logger.debug('----------------------------')
          end
          page += 1
          if res != nil then

            logger.debug('!!check!!')
            Product.search(user, jans, 'jan')

            targets = res.keys
            targets.delete(:item_id)

            Item.import item_list, on_duplicate_key_update: {constraint_name: :for_upsert_items, columns: targets}
            List.import user_list, on_duplicate_key_ignore: {constraint_name: :for_upsert_lists}
            @account.update(
              current_item_num: page
            )

            if page >= @account.max_page then return end
          end
          sleep(0.5)
          results = results.next_page
        end
      end

    when 2 then
      #ヤフオク



    end
  end

end
