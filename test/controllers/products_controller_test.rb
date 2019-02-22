require 'test_helper'

class ProductsControllerTest < ActionDispatch::IntegrationTest
  test "should get check" do
    get products_check_url
    assert_response :success
  end

end
