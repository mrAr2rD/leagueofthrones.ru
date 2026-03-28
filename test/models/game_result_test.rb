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
    assert_equal 20, gr.suggested_points
  end

  test "suggested_points for last place" do
    gr = GameResult.new(place: 8, capitals: 0, dragons: 0, castles: 0)
    assert_equal 1, gr.suggested_points
  end

  test "house must be one of allowed values" do
    gr = game_results(:daenerys_game1)
    gr.house = "bolton"
    assert_not gr.valid?
  end

  test "house is required for occupied result" do
    gr = GameResult.new(game: games(:game_1b), player: players(:jon), place: 2, points: 11)
    assert_not gr.valid?
    assert_includes gr.errors[:house], "должен быть выбран для занятого слота"
  end

  test "house must be unique within one game" do
    gr = GameResult.new(game: games(:game_1a), player: players(:cersei), house: "stark", place: 3, points: 10)
    assert_not gr.valid?
    assert_includes gr.errors[:house], "уже выбран за этим столом"
  end

  test "player cannot reuse the same house in another game" do
    gr = GameResult.new(game: games(:game_1b), player: players(:daenerys), house: "stark", place: 2, points: 12)
    assert_not gr.valid?
    assert_includes gr.errors[:house], "уже использовался этим игроком"
  end

  test "house_name returns russian label" do
    assert_equal "Старк", game_results(:daenerys_game1).house_name
  end

  test "unique player per game" do
    existing = game_results(:daenerys_game1)
    duplicate = GameResult.new(game: existing.game, player: existing.player, place: 3)
    assert_not duplicate.valid?
  end
end
