class ItemsController < ApplicationController
  def search
    @login_user = current_user
    user = current_user.email
    @items = Item.where(user: user)
    @headers = Constants::HITEM
    @account = Account.find_or_create_by(user: user)
    if request.post? then
      search_url = params[:input_url]
      return if search_url == nil

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
      @account.update(
        current_item_num: 0
      )
      ItemSearchJob.perform_later(user, search_url, shop_id)
      #Item.search(user, search_url, shop_id)
    end

  end
end
