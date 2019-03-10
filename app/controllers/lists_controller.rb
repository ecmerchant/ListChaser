class ListsController < ApplicationController

  require 'csv'

  def show
    @login_user = current_user
    user = current_user.email
    @lists = List.where(user: user, status: 'listing')
    @headers = {
      item_id: 'SKU',
      product_id: 'ASIN',
      name: '商品名',
      price: '販売価格',
      shop_id: '仕入れ先',
      condition: '商品状態',
      cost: '仕入価格',
      availability: '在庫状況'
    }
    if request.post? then
      logger.debug("===============================")

      headers = Array.new
      File.open('app/others/Flat.File.PriceInventory.jp.txt', 'r', encoding: 'Windows-31J', undef: :replace, replace: '*') do |file|
        csv = CSV.new(file, encoding: 'Windows-31J', col_sep: "\t")
        csv.each do |row|
          headers.push(row)
        end
      end

      list_templates = ListTemplate.where(user: user)

      stream = ''
      headers.each do |row|
        buf = row.join("\t")
        stream = stream + buf + "\n"
      end

      @lists.each do |list|
        buf = Array.new
        price = Price.calc(user, list.item.price)
        point = (price * list_templates.find_by(header: "standard-price-points").value.to_f).round(0)
        if list.item.availability == true then
          qty = 1
        else
          qty = 0
        end
        buf = [
          list.item.item_id,
          price,
          point,
          qty,
          "JPY",
          "",
          "",
          "",
          "",
          "",
          "",
          "",
          "",
          list_templates.find_by(header: "leadtime-to-ship").value.to_i
        ]
        logger.debug(buf)
        buf = buf.join("\t")

        stream = stream + buf + "\n"
      end
      logger.debug("\n\n\n")
      logger.debug(stream)
      Product.feed_upload(user, stream)

      #Item.patrol
      #List.stock_update(user)
    end
  end
end
