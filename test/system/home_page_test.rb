require "application_system_test_case"

class HomePageTest < ApplicationSystemTestCase
  setup do
    @shop = shops(:regular)
    login(@shop)
  end

  test "navigating to products list" do
    visit home_url

    assert_selector "h1", text: "Home"
    click_on "Products list"

    assert_selector "h1", text: "Products list"
  end
end
