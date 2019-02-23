class ProductsController < ApplicationController

  require 'csv'

  def check
    @login_user = current_user
    user = current_user.email
    csv = nil
    @headers = Array.new
    File.open('app/others/Flat.File.Listingloader.jp.txt', 'r', encoding: 'Windows-31J', undef: :replace, replace: '*') do |file|
      csv = CSV.new(file, encoding: 'Windows-31J', col_sep: "\t")
      csv.each do |row|
        @headers.push(row)
      end
    end
    @items = List.where(user: user, status: 'before_listing')
    @body = Array.new
    @template = ListTemplate.where(user: user, list_type: '相乗り')
    @items.each do |temp|
      thash = Hash.new
      @template.each do |ch|
        thash[ch.header] = ch.value
      end
      
      @headers[2].each do |col|
        case col
        when 'sku' then
          thash['sku'] = temp.item_id
        when 'price' then
          thash['price'] = temp.product.new_price
        when 'standard-price-points' then
          thash['standard-price-points'] = (temp.product.new_price * 0.01).round(0)
        when 'product-id' then
          thash['product-id'] = temp.item.jan
        when 'product-id-type' then
          thash['product-id-type'] = 'JAN'
        else

        end
      end
      @body.push(thash)
    end

    if request.post? then

    end
  end

  def csv_download
    user = current_user.email
    respond_to do |format|
      format.html do
          #html用の処理を書く
      end
      format.csv do
        @headers = Array.new
        File.open('app/others/Flat.File.Listingloader.jp.txt', 'r', encoding: 'Windows-31J', undef: :replace, replace: '*') do |file|
          csv = CSV.new(file, encoding: 'Windows-31J', col_sep: "\t")
          csv.each do |row|
            @headers.push(row)
          end
        end
        @items = List.where(user: user, status: 'before_listing')
        @body = Array.new
        @template = ListTemplate.where(user: user, list_type: '相乗り')
        @items.each do |temp|
          thash = Hash.new
          @template.each do |ch|
            thash[ch.header] = ch.value
          end

          @headers[2].each do |col|
            case col
            when 'sku' then
              thash['sku'] = temp.item_id
            when 'price' then
              thash['price'] = temp.product.new_price
            when 'standard-price-points' then
              thash['standard-price-points'] = (temp.product.new_price * 0.01).round(0)
            when 'product-id' then
              thash['product-id'] = temp.item.jan
            when 'product-id-type' then
              thash['product-id-type'] = 'JAN'
            else

            end
          end
          @body.push(thash)
        end
        fname = "アマゾン出品ファイル_" + Time.now.strftime("%Y%m%D%H%M%S") + ".txt"
        send_data render_to_string, filename: fname, type: :csv
      end
    end
  end

end
