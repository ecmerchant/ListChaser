class ProductsController < ApplicationController

  require 'csv'

  def check
    @login_user = current_user
    user = current_user.email
    csv = nil
    File.open('app/others/Flat.File.Listingloader.jp.txt', 'r', encoding: 'Windows-31J', undef: :replace, replace: '*') do |file|
      csv = CSV.new(file, encoding: 'Windows-31J', col_sep: "\t")
      csv.each do |row|
        logger.debug(row)
      end
    end



    if request.post? then

    end
  end
end
