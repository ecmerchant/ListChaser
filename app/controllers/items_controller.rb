class ItemsController < ApplicationController

  PER = 90
  def search
    @login_user = current_user
    user = current_user.email

    @account = Account.find_or_create_by(user: user)
    @shop_id = @account.shop_id

    if params[:page].to_i > 1 then
      @stnum = (params[:page].to_i - 1) * PER
    else
      @stnum = 0
    end

    @items = List.where(user: user, shop_id: @shop_id).where('(status = ?) OR (status = ?)', 'searching', 'before_listing').order('profit DESC NULLS LAST').page(params[:page]).per(PER)
    @total = List.where(user: user, status:'searching', shop_id: @shop_id).count
    @headers = Constants::HITEM

    @converter = Converter.all
    @search_condition = RakutenSearch.find_or_create_by(user: user)
    @yahoo_search_condition = YahooAucSearch.find_or_create_by(user: user)
    if request.post? then
      keyword = params[:input_key]
      input_url = params[:input_url]
      amazon_condition = params[:condition]

      return if keyword == nil && input_url == nil
      @search_condition.update(
        keyword: keyword
      )
      @yahoo_search_condition.update(
        search_url: input_url
      )

      shop_id = params[:shop].to_i
      if shop_id == 1 then
        keyword = keyword
      else
        keyword = input_url
      end
      @account.update(
        current_item_num: 0,
        shop_id: shop_id.to_s
      )
      ItemSearchJob.perform_later(user, keyword, shop_id, amazon_condition)
      #Item.search(user, keyword, shop_id, amazon_condition)
      redirect_to items_search_path
    end
  end

  def select
    if request.post? then
      logger.debug(params)
      user = current_user.email
      temp = List.where(user: user)
      List.where(user: user).where(status: 'before_listing').update(
        status: 'before_sale'
      )
      targets = params[:checked]
      if targets != nil then
        targets.each do |key, value|
          item_id = key
          tag = temp.find_by(item_id: item_id)
          tag.update(
            status: 'before_listing',
            point: (tag.price.to_f * 0.01).round(0),
          )
        end
      end
    end
    redirect_to products_check_path
  end

end
