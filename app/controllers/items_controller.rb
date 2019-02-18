class ItemsController < ApplicationController
  PER = 30
  def search
    @login_user = current_user
    user = current_user.email
    @items = Item.where(user: user).page(params[:page]).per(PER)
    @total = Item.where(user: user).count
    @headers = Constants::HITEM
    @account = Account.find_or_create_by(user: user)
    if request.post? then
      keyword = params[:input_key]
      return if keyword == nil
      search_url = "search.rakuten.co.jp"
      #仕入れ先の判別
      if search_url.include?("search.rakuten.co.jp") then
        #楽天市場
        logger.debug("========= Rakuten ==========")
        shop_id = 1
      elsif search_url.include?("auctions.yahoo.co.jp") then
        #ヤフオク
        logger.debug("========= Yahoo! ==========")
        shop_id = 2
      end
      shop_id = 1
      @account.update(
        current_item_num: 0
      )
      ItemSearchJob.perform_later(user, keyword, shop_id)
      #Item.search(user, keyword, shop_id)
    end

  end
end
