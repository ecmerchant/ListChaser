require 'test_helper'

class YahooAucSearchesControllerTest < ActionDispatch::IntegrationTest
  test "should get setup" do
    get yahoo_auc_searches_setup_url
    assert_response :success
  end

end
