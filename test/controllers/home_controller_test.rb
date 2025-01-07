require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @shop = shops(:regular)
    login(@shop)
  end

  test "renders home page" do
    get home_path

    assert_response :success
    assert_select "h1", "Home"
  end
end
