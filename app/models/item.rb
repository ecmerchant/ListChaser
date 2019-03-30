class Item < ApplicationRecord
  belongs_to :shop, primary_key: 'shop_id', optional: true
  belongs_to :converter, primary_key: 'keyword', foreign_key: 'keyword'

  require 'activerecord-import'
  require 'extension/string'
  require 'rakuten_web_service'
  require 'open-uri'
  require 'nokogiri'

  def self.search(user, keyword, shop_id, amazon_condition)
    logger.debug("========= SEARCH ==========")
    @account = Account.find_or_create_by(user: user)
    @account.update(
      current_item_num: 0
    )

    case shop_id
    when 1 then
      #楽天市場 API
      logger.debug("========= RakutenSearch ==========")
      titem = Item.all

      List.where(user: user, status: 'searching', shop_id: shop_id).update(
        status: 'before_sale'
      )

      RakutenWebService.configure do |c|
        c.application_id = ENV['RAKUTEN_APP_ID']
      end

      search_condition = Hash.new
      temp = RakutenSearch.find_by(user: user)

      RakutenSearch.column_names.each do |t|
        if t != 'user' && t != 'id' then
          if temp[t] != '' && temp[t] != nil then
            search_condition[t] = temp[t]
          end
        end
      end

      results = RakutenWebService::Ichiba::Item.search(search_condition)
      res = results.fetch_result

      item_num = results.count
      page = 1

      if item_num > 0 then
        #検索結果からアイテム取り出し
        counter = 0
        max_page = @account.max_page

        if res.page_count < max_page then
          max_page = res.page_count
        end
        if @account.current_item_num == 0 then
          @account.update(
            max_item_num: max_page
          )
        end
        res = Hash.new
        jans = []
        keywords = []

        while results.has_next_page?
          checker = Hash.new
          item_list = Array.new
          user_list = Array.new
          uhash = Hash.new

          results.each do |result|

            logger.debug('---------- No. ' + (counter + 1).to_s + ' -----------')
            url = result['itemUrl']
            item_id = result['itemCode'].gsub(':','_')
            image = result['mediumImageUrls'][0]
            name = result['itemName']
            price = result['itemPrice']
            availability = result['availability']
            if availability == 0 then
              availability = false
            else
              availability = true
            end

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
              keywords.push(keyword)
            end
            category_id = result['genreId']
            description = result['itemCaption']
            if jan == nil && description.jan != nil then
              jan = description.jan
              jans.push(jan)
            end

            mpn = nil

            condition = "New"
            if name.include?('中古') || description.include?('中古') then
              condition = "Used"
            end

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
              keyword: keyword,
              condition: condition,
              availability: availability
            }
            logger.debug(item_id)

            if checker.key?(item_id) == false then
              item_list << Item.new(res)
              uhash[item_id] = {user: user, item_id: item_id, status: 'searching', price: price}
              checker[item_id] = name
              counter += 1
            end
            logger.debug('----------------------------')
          end
          page += 1
          if res != nil then
            targets = res.keys
            targets.delete(:item_id)
            Item.import item_list, on_duplicate_key_update: {constraint_name: :for_upsert_items, columns: targets}

            logger.debug('!!check!!')
            Product.search(user, jans, 'jan', amazon_condition)

            if keywords[0] != nil then
              Product.search(user, keywords, 'keyword', amazon_condition)
            end

            uhash.each do |key, value|
              tt = Item.find_by(item_id: key)
              logger.debug(key)
              if tt.converter != NilClass && tt.converter != nil then
                ptemp = tt.converter.product
                if ptemp != NilClass && ptemp != nil then
                  pid = ptemp.product_id
                  pprice = ptemp.new_price + ptemp.new_point - ptemp.new_shipping
                  tprice = Price.calc(user, value[:price])
                  profit = (pprice.to_f * (1.0 - ptemp.amazon_fee).to_f - tt.price.to_f).round(0)

                  logger.debug(tprice)
                  logger.debug(tt.price.to_f)
                  logger.debug(profit)

                else
                  pid = nil
                  profit = nil
                end
              else
                pid = nil
                profit = nil
              end

              logger.debug(value)
              buf = value
              buf[:price] = tprice
              buf[:product_id] = pid
              buf[:profit] = profit
              buf[:shop_id] = shop_id
              logger.debug(buf)
              user_list << List.new(buf)
            end

            List.import user_list, on_duplicate_key_update: {constraint_name: :for_upsert_lists, columns: [:status, :product_id, :profit, :price, :shop_id]}
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
      logger.debug("========= YahooAucSearch ==========")
      List.where(user: user, status: 'searching', shop_id: shop_id).update(
        status: 'before_sale'
      )
      org_url = keyword
      if org_url.include?("&n=") == false then
        org_url = org_url + "&n=100"
      else
        tb = /\&n=([\s\S]*?)\&/.match(org_url)[1]
        org_url = org_url.gsub("&n=" + tb.to_s , "&n=100")
      end

      if org_url.include?("&b=1") == false then
        org_url = org_url + "&b=1"
      end

      ua = CSV.read('app/others/User-Agent.csv', headers: false, col_sep: "\t")
      counter = 0
      max_page = 1

      (1..100).each do |page|
        #各ページにアクセス
        logger.debug("---------------------------------")
        turl = org_url.gsub("&b=1", "&b=" + (1 + (page - 1) * 100).to_s)
        logger.debug(turl)
        option = {
          #{}"User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100"
          "User-Agent" => ua.sample[0]
        }
        charset = nil
        html = open(turl, option) do |f|
          charset = f.charset
          f.read
        end

        if page == 1 then
          nr = /<p class="total">([\s\S]*?)<\/p>/.match(html)[1]
          nr = /<em>([\s\S]*?)<\/em>/.match(nr)[1]
          max_page = (nr.to_i / 100) + 1
          if max_page > 100 then
            max_page = 100
          end
          @account.update(
            max_item_num: max_page
          )
        end

        item_list = Array.new
        user_list = Array.new
        uhash = Hash.new
        query = Array.new

        doc = Nokogiri::HTML.parse(html, nil, charset)
        hits = html.scan(/<tr><td class="i">([\s\S]*?)class="s1">/)

        if hits[0] == nil then
          hits = html.scan(/<div class="i">([\s\S]*?)<p class="ft">/)
          if hits[0] == nil then
            logger.debug("----- No -----")
            logger.debug(html)
            break
          end
        end
        result = nil
        hits.each do |hit|
          src = hit[0]

          title = /<h3>([\s\S]*?)<\/h3>/.match(src)[1]
          if src.include?('<span class="cic1">新品</span>') then
            condition = "New"
          else
            condition = "Used"
          end
          availability = false
          if title != nil then
            url = /href="([\s\S]*?)"/.match(title)[1]
            item_id = /auction\/([\s\S]*?)$/.match(url)[1]
            if title.include?("<em>") then
              title = /<em>([\s\S]*?)</.match(title)[1]
            else
              title = />([\s\S]*?)</.match(title)[1]
            end
            availability = true
          else
            url = ""
            title = ""
            item_id = ""
          end
          image = /src="([\s\S]*?)"/.match(src)[1]
          price = /<td class="pr2">([\s\S]*?)<\/td>/.match(src)
          if price != nil then
            price = price[1]
            if price.include?("<span>") then
              price = /<td class="pr1">([\s\S]*?)円/.match(src)[1]
              price = price.gsub("\n", "")
              price = price.gsub("\r", "")
              price = price.gsub(",", "")
            else
              price = /^([\s\S]*?)円/.match(price)[1]
              price = price.gsub("\n", "")
              price = price.gsub("\r", "")
              price = price.gsub(",", "")
            end
          else
            price = /即決([\s\S]*?)<\/dd>/.match(src)
            if price != nil then
              price = price[1]
              price = /dd>([\s\S]*?)円/.match(price)[1]
              price = price.gsub(",", "")
            else
              price = /現在([\s\S]*?)<\/dd>/.match(src)
              price = price[1]
              price = /dd>([\s\S]*?)円/.match(price)[1]
              price = price.gsub(",", "")
            end
          end
          counter += 1
          jan = ""
          mpn = ""
          logger.debug("--------------------------------")
          logger.debug("No. " + counter.to_s)
          logger.debug(item_id)
          logger.debug(title)
          logger.debug(price)
          logger.debug(url)
          logger.debug(image)
          result = Array.new
          result = {
            item_id: item_id,
            name: title,
            price: price,
            image: image,
            url: url,
            jan: jan,
            mpn: mpn,
            description: "",
            category_id: "",
            shop_id: shop_id,
            keyword: title,
            condition: condition,
            availability: availability
          }
          query.push(title)
          item_list << Item.new(result)
          uhash[item_id] = {user: user, item_id: item_id, status: 'searching', price: price}
        end
        sleep(0.5)
        if result != nil then
          targets = result.keys
          targets.delete(:item_id)
          Item.import item_list, on_duplicate_key_update: {constraint_name: :for_upsert_items, columns: targets}
        end

        Product.search(user, query, 'keyword', amazon_condition)

        uhash.each do |key, value|
          tt = Item.find_by(item_id: key)
          logger.debug(key)
          if tt.converter != NilClass && tt.converter != nil then
            ptemp = tt.converter.product
            if ptemp != NilClass && ptemp != nil then
              pid = ptemp.product_id
              pprice = ptemp.new_price + ptemp.new_point - ptemp.new_shipping
              tprice = Price.calc(user, value[:price])
              profit = (pprice.to_f * (1.0 - ptemp.amazon_fee).to_f - tt.price.to_f).round(0)

              logger.debug(tprice)
              logger.debug(tt.price.to_f)
              logger.debug(profit)

            else
              pid = nil
              profit = nil
            end
          else
            pid = nil
            profit = nil
          end

          logger.debug(value)
          buf = value
          buf[:price] = tprice
          buf[:product_id] = pid
          buf[:profit] = profit
          buf[:shop_id] = shop_id
          logger.debug(buf)
          user_list << List.new(buf)
        end

        List.import user_list, on_duplicate_key_update: {constraint_name: :for_upsert_lists, columns: [:status, :product_id, :profit, :price, :shop_id]}
        @account.update(
          current_item_num: page
        )

      end

    end
  end

  def self.patrol
    #出品中の楽天商品を定期監視
    logger.debug("\n\n---------------------------")
    targets = List.where(status: 'listing').group(:item_id).pluck(:item_id)
    logger.debug(targets)
    RakutenWebService.configure do |c|
      c.application_id = ENV['RAKUTEN_APP_ID']
    end

    targets.each_slice(100) do |items|
      res = Hash.new
      item_list = Array.new
      checker = Hash.new

      items.each do |item_id|
        item_id.gsub!("_", ":")
        results = RakutenWebService::Ichiba::Item.search({itemCode: item_id})
        results.each do |result|
          url = result['itemUrl']
          item_id = result['itemCode'].gsub(':','_')
          image = result['mediumImageUrls'][0]
          name = result['itemName']
          price = result['itemPrice']
          availability = result['availability']
          if availability == 0 then
            availability = false
          else
            availability = true
          end
          code = url.gsub('https://item.rakuten.co.jp/','')
          code = /\/([\s\S]*?)\//.match(code)[1]
          logger.debug(code)
          if code.end_with?("_") then
            code.chop!
          end
          if code.jan? then
            jan = code
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

          condition = "New"
          if name.include?('中古') || description.include?('中古') then
            condition = "Used"
          end

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
            shop_id: 1,
            keyword: keyword,
            condition: condition,
            availability: availability
          }
          logger.debug(item_id)
          if checker.key?(item_id) == false then
            item_list << Item.new(res)
            checker[item_id] = name
          end
          logger.debug('----------------------------')
        end
      end

      if res != nil then
        targets = res.keys
        targets.delete(:item_id)
        Item.import item_list, on_duplicate_key_update: {constraint_name: :for_upsert_items, columns: targets}
      end
    end
  end

end
