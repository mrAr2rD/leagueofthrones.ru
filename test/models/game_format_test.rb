require "test_helper"

class GameFormatTest < ActiveSupport::TestCase
  test "default format is mother of dragons" do
    assert_equal "mother_of_dragons", GameFormat.default.key
    assert_equal GameFormat.default, GameFormat.find(nil)
    assert_equal GameFormat.default, GameFormat.find("unknown")
  end

  test "mother of dragons parameters" do
    mod = GameFormat.find("mother_of_dragons")

    assert_equal 8, mod.players_per_table
    assert_equal 8, mod.tour_default_count
    assert_equal (1..8), mod.place_range
    assert_equal 8, mod.houses.size
    assert_equal 12, mod.place_points_for(1)
    assert_equal 1, mod.place_points_for(8)
    assert mod.table_a_bonus?(3)
    assert_not mod.table_a_bonus?(4)
  end

  test "mother of dragons castles are linear capped at 5" do
    mod = GameFormat.find("mother_of_dragons")

    assert_equal 0, mod.castle_points(0)
    assert_equal 3, mod.castle_points(3)
    assert_equal 5, mod.castle_points(5)
    assert_equal 5, mod.castle_points(9)
  end

  test "classic parameters" do
    classic = GameFormat.find("classic")

    assert_equal 6, classic.players_per_table
    assert_equal 6, classic.tour_default_count
    assert_equal (1..6), classic.place_range
    assert_equal %w[stark lannister baratheon greyjoy tyrell martell], classic.house_keys
    assert_not_includes classic.house_keys, "arryn"
  end

  test "classic place points" do
    classic = GameFormat.find("classic")

    assert_equal({ 1 => 12, 2 => 8, 3 => 6, 4 => 4, 5 => 2, 6 => 1 }, classic.place_points)
  end

  test "classic table A bonus only for places 1 and 2" do
    classic = GameFormat.find("classic")

    assert classic.table_a_bonus?(1)
    assert classic.table_a_bonus?(2)
    assert_not classic.table_a_bonus?(3)
  end

  test "classic castles use bands" do
    classic = GameFormat.find("classic")

    assert_equal 0, classic.castle_points(0)
    assert_equal 0, classic.castle_points(1)
    assert_equal 1, classic.castle_points(2)
    assert_equal 1, classic.castle_points(3)
    assert_equal 2, classic.castle_points(4)
    assert_equal 2, classic.castle_points(5)
    assert_equal 3, classic.castle_points(6)
    assert_equal 4, classic.castle_points(7)
    assert_equal 4, classic.castle_points(99)
  end

  test "league tier size equals players per table" do
    assert_equal 8, GameFormat.find("mother_of_dragons").league_tier_size
    assert_equal 6, GameFormat.find("classic").league_tier_size
  end

  test "to_config_json is the contract shared with the JS calculator" do
    classic = JSON.parse(GameFormat.find("classic").to_config_json)

    assert_equal 12, classic["placePoints"]["1"]
    assert_equal [ 1, 2 ], classic["tableABonusPlaces"]
    assert_equal 3, classic["capitalCap"]
    assert_equal "band", classic["castleRule"]["type"]
    # Открытый верхний диапазон сериализуется как null (JS трактует как бесконечность).
    assert_equal [ 7, nil, 4 ], classic["castleRule"]["table"].last

    mod = JSON.parse(GameFormat.find("mother_of_dragons").to_config_json)
    assert_equal "linear_cap", mod["castleRule"]["type"]
    assert_equal 5, mod["castleRule"]["cap"]
  end
end
