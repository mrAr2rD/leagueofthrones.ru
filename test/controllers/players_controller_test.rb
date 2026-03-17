require "test_helper"

class PlayersControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get player_url(players(:daenerys))
    assert_response :success
    assert_match "Семён", response.body
  end
end
