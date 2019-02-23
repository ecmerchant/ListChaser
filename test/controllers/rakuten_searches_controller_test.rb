require 'test_helper'

class RakutenSearchesControllerTest < ActionDispatch::IntegrationTest
  test "should get setup" do
    get rakuten_searches_setup_url
    assert_response :success
  end

end
