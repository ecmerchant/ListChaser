class RakutenSearchesController < ApplicationController

  def setup
    @login_user = current_user
    user = current_user.email
    @rakuten_search = RakutenSearch.find_or_create_by(user: user)
    @amazon_search = AmazonSearch.where(user: user)
    @headers = {
      keyword: '検索キーワード',
      ng_keyword: '除外キーワード',
      genre_id: 'ジャンルID',
      min_price: '最低価格',
      max_price: '最高価格',
      postage_flag: '送料フラグ'
    }
    @headers_info = {
      keyword: 'キーワード',
      ng_keyword: '除外したいキーワード',
      genre_id: "ジャンルIDは検索URL内の/category/xxx/のxxxの部分.　<br>例：家電）https://www.rakuten.co.jp/category/562637/の場合は562637",
      min_price: '最低価格',
      max_price: '最高価格',
      postage_flag: "0 :すべての商品, 1 :送料込み／送料無料の商品のみ"
    }
    if request.post? then
      @rakuten_search.update(user_params)
      redirect_to items_search_path
    end
  end

  def edit
    if request.post? then
      keywords = params['text']
      user = current_user.email
      amazon = AmazonSearch.where(user: user)
      keywords.each do |key,value|
        if value != "" then
          amazon.find_or_create_by(ng_keyword: value)
        end
      end
    end
    redirect_to rakuten_searches_setup_path
  end

  def import
    if request.post? then
      data = params[:ng_import]
      if data != nil then
        ext = File.extname(data.path)
        if ext == ".xls" || ext == ".xlsx" then
          user = current_user.email
          temp = AmazonSearch.where(user: current_user.email)
          if temp != nil then
            temp.delete_all
          end
          logger.debug("=== UPLOAD ===")

          workbook = RubyXL::Parser.parse(data.path)
          worksheet = workbook.first
          worksheet.each_with_index do |row, i|
            if row[0].value == nil then break end
            if i > 0 then
              value = row[0].value.to_s
              logger.debug(value)
              AmazonSearch.find_or_create_by(
                user: user,
                ng_keyword: value
              )
            end
          end
        end
      end
      redirect_to rakuten_searches_setup_path
    end
  end

  def template
    user = current_user.email
    respond_to do |format|
      format.html
      format.xlsx do
        @workbook = RubyXL::Workbook.new
        @sheet = @workbook.first

        @sheet.add_cell(0, 0, "除外キーワード")

        data = @workbook.stream.read
        timestamp = Time.new.strftime("%Y%m%d%H%M%S")
        send_data data, filename: "除外設定テンプレート_" + timestamp + ".xlsx", type: "application/xlsx", disposition: "attachment"
      end
    end
  end

  private
  def user_params
     params.require(:rakuten_search).permit(:user, :keyword, :shop_code, :item_code, :genre_id, :tag_id, :sort, :min_price, :max_price, :ng_keyword, :postage_flag)
  end

end
