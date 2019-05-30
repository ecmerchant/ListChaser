class AccountsController < ApplicationController

  before_action :authenticate_user!, :except => [:regist]
  protect_from_forgery :except => [:regist]

  def setup
    @login_user = current_user
    user = current_user.email
    @account = Account.find_or_create_by(user: user)
    if request.post? then
      @account.update(user_params)
    end
  end

  def regist
    if request.post? then
      logger.debug("====== Regist from Form Start =======")
      user = params[:user]
      password = params[:password]
      if User.find_by(email: user) == nil then
        #新規登録
        init_password = password
        tuser = User.create(email: user, password: init_password, admin_flg: false)
        Account.find_or_create_by(user: user)
        return
      end
    end
    redirect_to root_url
  end

  private
  def user_params
     params.require(:account).permit(:user, :seller_id, :mws_auth_token, :rakuten_app_id)
  end

end
