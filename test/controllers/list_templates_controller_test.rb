require 'test_helper'

class ListTemplatesControllerTest < ActionDispatch::IntegrationTest
  test "should get setup" do
    get list_templates_setup_url
    assert_response :success
  end

end
