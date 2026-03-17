require "test_helper"

class GameResultTest < ActiveSupport::TestCase
  test "valid game result" do
    gr = game_results(:daenerys_game1)
    assert gr.valid?
  end

  test "place must be 1-8" do
    gr = game_results(:daenerys_game1)
    gr.place = 9
    assert_not gr.valid?
  end

  test "suggested_points calculation" do
    gr = GameResult.new(place: 1, capitals: 2, dragons: 1, castles: 0)
    # 15 + (2*2) + 1 + 0 = 20
    assert_equal 20, gr.suggested_points
  end

  test "suggested_points for last place" do
    gr = GameResult.new(place: 8, capitals: 0, dragons: 0, castles: 0)
    assert_equal 1, gr.suggested_points
  end

  test "unique player per game" do
    existing = game_results(:daenerys_game1)
    duplicate = GameResult.new(game: existing.game, player: existing.player, place: 3)
    assert_not duplicate.valid?
  end
end
