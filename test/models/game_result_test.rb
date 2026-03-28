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

  test "suggested_points follows published rules for table A" do
    gr = GameResult.new(game: games(:game_1a), place: 1, capitals: 2, dragons: 1, castles: 0)
    assert_equal 16, gr.suggested_points
  end

  test "suggested_points for last place without bonuses" do
    gr = GameResult.new(game: games(:game_1b), place: 8, capitals: 0, dragons: 0, castles: 0)
    assert_equal 1, gr.suggested_points
  end

  test "suggested_points caps capital and castle bonuses" do
    gr = GameResult.new(game: games(:game_1a), place: 3, capitals: 7, dragons: 2, castles: 9)
    assert_equal 17, gr.suggested_points
  end

  test "manual points remain the source of truth" do
    game = Game.create!(tour: tours(:tour_two), table_letter: "A")
    gr = GameResult.new(
      game: game,
      player: players(:daenerys),
      house: "baratheon",
      place: 2,
      points: 999,
      capitals: 1,
      dragons: 0,
      castles: 2
    )

    assert gr.valid?
    assert_equal 999, gr.points
    assert_equal 11, gr.suggested_points
  end

  test "capital values above scoring cap are still valid" do
    gr = game_results(:daenerys_game1)
    gr.capitals = 10

    assert gr.valid?
    assert_equal 17, gr.suggested_points
  end

  test "castle values above scoring cap are still valid" do
    gr = game_results(:daenerys_game1)
    gr.castles = 10

    assert gr.valid?
    assert_equal 21, gr.suggested_points
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

  test "player must be unique within one game" do
    gr = GameResult.new(game: games(:game_1a), player: players(:daenerys), house: "arryn", place: 3, points: 10)
    assert_not gr.valid?
    assert_includes gr.errors[:player_id], "уже выбран за этим столом"
  end

  test "player must be unique within one tour" do
    gr = GameResult.new(game: games(:game_1b), player: players(:daenerys), house: "arryn", place: 2, points: 12)
    assert_not gr.valid?
    assert_includes gr.errors[:player_id], "уже выбран за другим столом этого тура"
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
