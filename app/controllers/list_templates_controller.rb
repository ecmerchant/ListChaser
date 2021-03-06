class ListTemplatesController < ApplicationController

  def setup
    @login_user = current_user
    user = current_user.email
    @headers = Array.new
    @template = ListTemplate.where(user: user, list_type: '相乗り')
    @notes = ConditionNote.where(user: user)
    if @notes.count < 1 then
      for t in 1..10 do
        @notes.find_or_create_by(
          number: t
        )
      end
    end
    File.open('app/others/Flat.File.Listingloader.jp.txt', 'r', encoding: 'Windows-31J', undef: :replace, replace: '*') do |file|
      csv = CSV.new(file, encoding: 'Windows-31J', col_sep: "\t")
      csv.each do |row|
        @headers.push(row)
      end
    end

    if request.post? then
      target = ListTemplate.where
      data = params[:text]
      data.each do |key, value|
        temp = ListTemplate.find_or_create_by(user: user, list_type: '相乗り', header: key)
        temp.update(
          value: value
        )
      end
      notes = params[:note]
      memos = params[:memo]

      notes.each do |key, value|
        buf = @notes.find_or_create_by(number: key.to_i)
        buf.update(
          memo: memos[key],
          content: value
        )
      end

    end
  end

end
