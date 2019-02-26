class AccountsController < ApplicationController
  
  def setup
    @login_user = current_user
    user = current_user.email
    @account = Account.find_or_create_by(user: user)
    if request.post? then
      @account.update(user_params)
    end
  end

  private
  def user_params
     params.require(:account).permit(:user, :seller_id, :mws_auth_token, :rakuten_app_id)
  end

end
