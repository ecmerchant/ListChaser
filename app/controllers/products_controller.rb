class ProductsController < ApplicationController

  require 'csv'
  require 'peddler'

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

    @notes = ConditionNote.where(user: user)
    @selection = Array.new
    @notes.each do |nt|
      key = nt.number.to_s + " :" + nt.memo
      @selection.push(nt.content)
    end

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
          thash['price'] = temp.price
        when 'standard-price-points' then
          thash['standard-price-points'] = temp.point
        when 'product-id' then
          thash['product-id'] = temp.item.jan
        when 'product-id-type' then
          thash['product-id-type'] = 'EAN'
        when 'condition_note' then
          thash['condition_note'] = temp.condition_note
        else

        end
      end
      @body.push(thash)
    end

    if request.post? then
      if params[:commit] == 'MWSアップロード' then
        stream = ''
        @headers.each do |row|
          buf = row.join("\t")
          stream = stream + buf + "\n"
        end
        @body.each do |row|
          buf = ''
          @headers[2].each_with_index do |col, index|
            buf = buf + row[col].to_s + "\t" if index < @headers[2].length - 1
          end
          buf = buf + row[@headers[2].last]
          stream = stream + buf + "\n"
        end
        Product.feed_upload(user, stream)
        @items.update(
          status: 'listing'
        )
      else
        new_price = params[:price]
        logger.debug(new_price)
        new_price.each do |key, value|
          @items.find_by(item_id: key).update(
            price: value.to_i
          )
        end

        new_point = params[:point]
        new_point.each do |key, value|
          @items.find_by(item_id: key).update(
            point: value.to_i
          )
        end

        condition_note = condition_note[:point]
        condition_note.each do |key, value|
          @items.find_by(item_id: key).update(
            condition_note: value.to_s
          )
        end

      end
      redirect_to products_check_path
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
              thash['product-id-type'] = 'EAN'
            else

            end
          end
          @body.push(thash)
        end
        fname = "アマゾン出品ファイル_" + Time.now.strftime("%Y%m%D%H%M%S") + ".txt"
        send_data render_to_string, filename: fname, type: :csv
        @items.update(
          status: 'listing'
        )
      end
    end
  end

end
