class YahooAucSearchesController < ApplicationController

  def setup
    @login_user = current_user
    user = current_user.email
    @yahoo_auc_search = YahooAucSearch.find_or_create_by(user: user)
    @headers = {
      keyword: '検索キーワード',
      ng_keyword: '除外キーワード',
      condition: '商品状態',
      category: 'カテゴリ',
      sales_type: '販売形式',
      min_cur_price: '最低_現在価格',
      max_cur_price: '最高_現在価格',
      min_bin_price: '最低_即決価格',
      max_bin_price: '最高_即決価格',
    }
    if request.post? then
      @yahoo_auc_search.update(user_params)
      redirect_to items_search_path
    end
  end

  private
  def user_params
     params.require(:yahoo_auc_search).permit(:user, :keyword, :ng_keyword, :condition, :sales_type, :category, :min_cur_price, :max_cur_price, :min_bin_price, :max_bin_price)
  end

end
