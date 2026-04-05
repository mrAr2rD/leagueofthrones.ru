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

  test "effective capitals falls back to legacy capitals when new fields are nil" do
    gr = game_results(:daenerys_game1)

    assert gr.using_legacy_capitals?
    assert_equal 2, gr.effective_capitals
    assert_equal 2, gr.capital_bonus_points
  end

  test "effective capitals uses split fields once any new field is present" do
    gr = game_results(:cersei_game1)

    assert_not gr.using_legacy_capitals?
    assert_equal 1, gr.effective_capitals
    assert_equal 1, gr.capital_bonus_points
  end

  test "ranking captures fall back to legacy capitals when split fields are nil" do
    assert_equal 2, game_results(:daenerys_game1).ranking_captures
  end

  test "ranking captures use only capital captures for new-format records" do
    assert_equal 1, game_results(:cersei_game1).ranking_captures
  end

  test "ranking captures ignore capital controls" do
    gr = GameResult.new(
      capitals: 99,
      capital_captures: nil,
      capital_controls: 2
    )

    assert_equal 0, gr.ranking_captures
  end

  test "suggested_points uses legacy capitals when split fields are blank" do
    gr = GameResult.new(game: games(:game_1a), place: 1, capitals: 2, dragons: 1, castles: 0)

    assert_equal 16, gr.suggested_points
  end

  test "suggested_points uses split capitals instead of legacy value" do
    gr = GameResult.new(
      game: games(:game_1a),
      place: 1,
      capitals: 99,
      capital_captures: 1,
      capital_controls: 1,
      dragons: 1,
      castles: 0
    )

    assert_equal 16, gr.suggested_points
  end

  test "suggested_points treats blank split capital half as zero" do
    gr = GameResult.new(
      game: games(:game_1a),
      place: 2,
      capitals: 99,
      capital_captures: nil,
      capital_controls: 2,
      dragons: 0,
      castles: 2
    )

    assert_equal 12, gr.suggested_points
  end

  test "suggested_points for last place without bonuses" do
    gr = GameResult.new(game: games(:game_1b), place: 8, capitals: 0, dragons: 0, castles: 0)
    assert_equal 1, gr.suggested_points
  end

  test "suggested_points caps split capital and castle bonuses" do
    gr = GameResult.new(
      game: games(:game_1a),
      place: 3,
      capital_captures: 3,
      capital_controls: 2,
      dragons: 2,
      castles: 9
    )

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
      capital_captures: 1,
      capital_controls: 0,
      dragons: 0,
      castles: 2
    )

    assert gr.valid?
    assert_equal 999, gr.points
    assert_equal 11, gr.suggested_points
  end

  test "split bonus fields must be non-negative integers" do
    gr = game_results(:daenerys_game1)
    gr.capital_captures = -1
    gr.lands = -2
    gr.skulls = -3

    assert_not gr.valid?
    assert_includes gr.errors[:capital_captures], "must be greater than or equal to 0"
    assert_includes gr.errors[:lands], "must be greater than or equal to 0"
    assert_includes gr.errors[:skulls], "must be greater than or equal to 0"
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
