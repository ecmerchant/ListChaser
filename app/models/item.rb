class Item < ApplicationRecord
  #belongs_to :seller, primary_key: 'seller_id', optional: true

  require 'typhoeus'
  require 'open-uri'
  require 'activerecord-import'
  require 'extension/string'

  def self.search(user, search_url, shop_id)
    case shop_id
    when 1 then
      #楽天市場
      #response = Typhoeus.get(search_url, followlocation: true)
      #html = response.body
      charset = nil
      html = open(search_url) do |f|
        charset = f.charset
        f.read
      end

      doc = Nokogiri::HTML.parse(html)
      temp = doc.xpath('//div[@class="dui-cards searchresultitems"]')
      if temp !=nil then
        results = temp.xpath('//div[@class="dui-card searchresultitem"]')
        #検索結果からアイテム取り出し
        item_list = Array.new
        return if results[0] == nil
        counter = 0
        results.each do |result|
          counter += 1
          logger.debug('---------- No. ' + counter.to_s + ' -----------')
          res = Hash.new
          url = result.xpath('.//a[@target="_top"]')[0][:href]
          item_id = url.gsub('https://item.rakuten.co.jp/','').gsub('/','_')
          if item_id.end_with?("_") then
            item_id.chop!
          end
          image = result.xpath('.//img[@class="_verticallyaligned"]')[0][:src]

          #個別ページにアクセス
          page = open(url) do |f|
            charset = f.charset
            f.read
          end
          page = Nokogiri::HTML.parse(page)

          price = page.xpath('//input[@id="ratPrice"]')[0]
          if price != nil then
            price = price[:value].to_i
          else
            price = 0
          end
          code = page.xpath('//input[@name="item_number"]')[0]
          if code != nil then
            code = code[:value].to_s
            if code.jan? then
              jan = code
            else
              jan = nil
            end
          else
            code = nil
            jan = nil
          end

          name = page.xpath('//span[@class="item_name"]')[0]
          name = name.inner_text if name != nil
          if jan != nil then
            keyword = jan
          else
            keyword = name
          end
          category_id = nil
          description = nil
          mpn = nil

          res = {
            user: user,
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
          item_list << Item.new(res)
          logger.debug('---------------------------')

          #return if counter > 2
        end
        if item_list[0] != nil then
          targets = item_list[0].keys
          targets.shift(2)
          Item.import item_list, on_duplicate_key_update: {constraint_name: :index_items_on_user_and_item_id, columns: targets}
        end
      end
      next_url = doc.xpath('//a[@class="item -next nextPage"]')
      if next_url != nil then
        next_url = next_url[0][:href]
        #self.search(next_url, shop_id)
      end
    when 2 then
      #ヤフオク



    end
  end

end
