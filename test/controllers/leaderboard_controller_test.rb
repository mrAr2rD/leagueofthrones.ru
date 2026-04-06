require "test_helper"

class LeaderboardControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_url
    assert_response :success
    assert_select "h1", /Игра Престолов/
  end

  test "shows player names" do
    get root_url
    assert_match "samzakharov", response.body
  end

  test "hides players without tournament participation" do
    Player.create!(first_name: "Публичный", nickname: "@public_board")
    Player.create!(first_name: "Скрытый", nickname: "@hidden_board", participates_in_tournament: false)

    get root_url

    assert_match "public_board", response.body
    assert_no_match "hidden_board", response.body
  end
end
