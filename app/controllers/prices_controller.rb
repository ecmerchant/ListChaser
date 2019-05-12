class PricesController < ApplicationController

  def edit
    user = current_user.email
    @prices = Price.where(user: user).order("original_price ASC NULLS LAST")
    @login_user = current_user

    if @prices.length == 0 then
      Price.find_or_create_by(
        user: user,
        original_price: 0,
        convert_price: 100
      )
      Price.find_or_create_by(
        user: user,
        original_price: 10000,
        convert_price: 14000
      )
      Price.find_or_create_by(
        user: user,
        original_price: 20000,
        convert_price: 26000
      )
      Price.find_or_create_by(
        user: user,
        original_price: 100000,
        convert_price: 120000
      )
      Price.find_or_create_by(
        user: user,
        original_price: 500000,
        convert_price: 600000
      )

    end

    if request.post? then
      data = params[:price_edit]
      if data != nil then
        ext = File.extname(data.path)
        if ext == ".xls" || ext == ".xlsx" then

          temp = Price.where(user: current_user.email)
          if temp != nil then
            temp.delete_all
          end
          logger.debug("=== UPLOAD ===")

          workbook = RubyXL::Parser.parse(data.path)
          worksheet = workbook.first
          worksheet.each_with_index do |row, i|
            if row[0].value == nil then break end
            if i > 0 then
              from = row[0].value.to_i
              to = row[1].value.to_i
              Price.find_or_create_by(
                user: user,
                original_price: from,
                convert_price: to
              )
            end
          end
        end
      end
      redirect_to prices_edit_path
    end
  end

  def template
    user = current_user.email
    respond_to do |format|
      format.html
      format.xlsx do
        @workbook = RubyXL::Workbook.new
        @sheet = @workbook.first

        @sheet.add_cell(0, 0, "仕入価格")
        @sheet.add_cell(0, 1, "販売価格")
        @sheet.add_cell(1, 0, 0)
        @sheet.add_cell(1, 1, 100)
        @sheet.add_cell(2, 0, 10000)
        @sheet.add_cell(2, 1, 14000)
        @sheet.add_cell(3, 0, 20000)
        @sheet.add_cell(3, 1, 26000)
        @sheet.add_cell(4, 0, 100000)
        @sheet.add_cell(4, 1, 120000)
        @sheet.add_cell(5, 0, 500000)
        @sheet.add_cell(5, 1, 600000)


        data = @workbook.stream.read
        timestamp = Time.new.strftime("%Y%m%d%H%M%S")
        send_data data, filename: "価格設定テンプレート_" + timestamp + ".xlsx", type: "application/xlsx", disposition: "attachment"
      end
    end
  end


end
