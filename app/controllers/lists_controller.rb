class ListsController < ApplicationController
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
  end
end
