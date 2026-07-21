require "test_helper"
require "securerandom"

class TournamentStatisticsCalculatorTest < ActiveSupport::TestCase
  setup do
    @city = City.create!(
      name: "Город статистики",
      slug: "statistics-#{SecureRandom.hex(5)}",
      default_format: "mother_of_dragons"
    )
    @player_sequence = 0
  end

  test "uses only played tours from the selected city and format" do
    target_player = create_player
    target_tour = create_tour(number: 1)
    create_result(create_game(target_tour), target_player, house: "stark", capitals: 2)

    unplayed_player = create_player
    unplayed_tour = create_tour(number: 2, played: false)
    create_result(create_game(unplayed_tour), unplayed_player, house: "lannister", capitals: 9)

    classic_player = create_player
    classic_tour = create_tour(number: 3, format: "classic")
    create_result(create_game(classic_tour), classic_player, house: "baratheon", capitals: 9)

    other_city = City.create!(name: "Другой город", slug: "other-#{SecureRandom.hex(5)}")
    other_tour = create_tour(number: 1, city: other_city)
    create_result(create_game(other_tour), create_player, house: "greyjoy", capitals: 9)

    result = calculate

    assert_equal [ target_player.id ], result.rows.map { |row| row.player.id }
    assert_equal 1, result.played_tours_count
    assert_equal 2, result.rows.first.captures
  end

  test "sums split and legacy captures without capital controls" do
    player = create_player
    first_tour = create_tour(number: 1)
    second_tour = create_tour(number: 2)
    create_result(create_game(first_tour), player, house: "stark", capitals: 3)
    create_result(
      create_game(second_tour),
      player,
      house: "lannister",
      capitals: 99,
      capital_captures: 2,
      capital_controls: 50
    )

    row = calculate.rows.find { |item| item.player.id == player.id }

    assert_equal 2, row.games_count
    assert_equal 5, row.captures
  end

  test "finds dragon and skull leaders including ties" do
    tour = create_tour(number: 1)
    game = create_game(tour)
    first = create_player
    second = create_player
    third = create_player
    create_result(game, first, house: "stark", place: 1, dragons: 3, skulls: 4)
    create_result(game, second, house: "lannister", place: 2, dragons: 3, skulls: 1)
    create_result(game, third, house: "baratheon", place: 3, dragons: 1, skulls: 4)

    result = calculate

    assert_equal [ first.id, second.id ].sort,
                 result.nomination("dragon_slayer").leaders.map { |row| row.player.id }.sort
    assert_equal [ first.id, third.id ].sort,
                 result.nomination("faceless_chosen").leaders.map { |row| row.player.id }.sort
  end

  test "does not select a leader for a zero maximum" do
    tour = create_tour(number: 1)
    create_result(create_game(tour), create_player, house: "stark", capitals: 0, dragons: 0, skulls: 0)

    result = calculate

    assert_equal 0, result.nomination("conqueror").max_value
    assert_empty result.nomination("conqueror").leaders
    assert_empty result.nomination("dragon_slayer").leaders
    assert_empty result.nomination("faceless_chosen").leaders
  end

  test "includes historical players who no longer participate" do
    inactive_player = create_player(participates_in_tournament: false)
    tour = create_tour(number: 1)
    create_result(create_game(tour), inactive_player, house: "stark", capitals: 1)

    assert_includes calculate.rows.map { |row| row.player.id }, inactive_player.id
  end

  test "reports a missing played tour" do
    result = calculate

    assert_not result.complete?
    assert_includes result.problems, "Нет ни одного сыгранного тура."
  end

  test "reports incomplete tables and missing values" do
    tour = create_tour(number: 1)
    game = create_game(tour)
    result_row = create_result(game, create_player, house: "stark", place: 1, skulls: 1)
    result_row.update_columns(house: nil, place: nil, points: nil, skulls: nil)

    result = calculate

    assert_not result.complete?
    assert result.problems.any? { |problem| problem.include?("ожидается 8 результатов, найдено 1") }
    assert result.problems.any? { |problem| problem.include?("дом, место, очки, черепки") }
  end

  test "reports duplicate and incomplete place ranges" do
    tour = create_tour(number: 1)
    game = create_game(tour)
    create_result(game, create_player, house: "stark", place: 1)
    create_result(game, create_player, house: "lannister", place: 1)

    result = calculate

    assert result.problems.any? { |problem| problem.include?("места должны быть уникальными") }
  end

  test "reports a player assigned to two tables of the same tour" do
    tour = create_tour(number: 1, tables_count: 2)
    player = create_player
    create_result(create_game(tour, "A"), player, house: "stark", place: 1)
    create_result(create_game(tour, "B"), player, house: "lannister", place: 1)

    result = calculate

    assert result.problems.any? { |problem| problem.include?("находится за несколькими столами (A, B)") }
  end

  test "reports results left in a table outside the current tour configuration" do
    tour = create_tour(number: 1, tables_count: 1)
    create_result(create_game(tour, "A"), create_player, house: "stark", place: 1)
    create_result(create_game(tour, "B"), create_player, house: "lannister", place: 1)

    result = calculate

    assert result.problems.any? do |problem|
      problem.include?("стол B: стол не входит в текущую настройку тура, но содержит результаты")
    end
  end

  test "classic format omits dragon and skull nominations" do
    tour = create_tour(number: 1, format: "classic")
    create_result(create_game(tour), create_player, house: "stark", dragons: 7, skulls: 9)

    result = TournamentStatisticsCalculator.call(city: @city, format: "classic")

    assert_equal [ "conqueror" ], result.nominations.map { |nomination| nomination.definition.key }
    assert_equal 0, result.rows.first.dragons
    assert_equal 0, result.rows.first.skulls
  end

  private

  def calculate
    TournamentStatisticsCalculator.call(city: @city, format: "mother_of_dragons")
  end

  def create_tour(number:, city: @city, format: "mother_of_dragons", played: true, tables_count: 1)
    Tour.create!(
      number: number,
      city: city,
      format: format,
      tables_count: tables_count,
      played: played,
      played_on: played ? Date.new(2026, 7, number) : nil
    )
  end

  def create_game(tour, table_letter = "A")
    Game.create!(tour: tour, table_letter: table_letter)
  end

  def create_player(participates_in_tournament: true)
    @player_sequence += 1
    Player.create!(
      first_name: "Игрок #{@player_sequence}",
      nickname: "@statistics_#{SecureRandom.hex(5)}",
      participates_in_tournament: participates_in_tournament
    )
  end

  def create_result(game, player, house:, place: 1, points: 10, capitals: 0,
                    capital_captures: nil, capital_controls: nil, dragons: 0, skulls: 0)
    GameResult.create!(
      game: game,
      player: player,
      house: house,
      place: place,
      points: points,
      capitals: capitals,
      capital_captures: capital_captures,
      capital_controls: capital_controls,
      lands: 0,
      skulls: skulls,
      dragons: dragons,
      castles: 0
    )
  end
end
