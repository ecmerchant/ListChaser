class RakutenSearchesController < ApplicationController

  def setup
    @login_user = current_user
    user = current_user.email
    @rakuten_search = RakutenSearch.find_or_create_by(user: user)
    @headers = {
      keyword: '検索キーワード',
      ng_keyword: '除外キーワード',
      shop_code: 'ショップID',
      item_code: 'アイテムID',
      genre_id: 'ジャンルID',
      tag_id: 'タグID',
      sort: 'ソート',
      min_price: '最低価格',
      max_price: '最高価格',
      postage_flag: '送料フラグ'
    }
    if request.post? then
      @rakuten_search.update(user_params)
      redirect_to items_search_path
    end
  end

  private
  def user_params
     params.require(:rakuten_search).permit(:user, :keyword, :shop_code, :item_code, :genre_id, :tag_id, :sort, :min_price, :max_price, :ng_keyword, :postage_flag)
  end

end
