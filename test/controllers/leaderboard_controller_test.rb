require "test_helper"

class LeaderboardControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_url
    assert_response :success
    assert_select "h1", /Игра Престолов/
  end

  test "shows player names" do
    get root_url
    assert_match "@samzakharov", response.body
  end
end
