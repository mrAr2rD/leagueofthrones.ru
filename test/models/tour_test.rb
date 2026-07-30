require "test_helper"

class TourTest < ActiveSupport::TestCase
  test "valid fixture tour" do
    assert tours(:tour_one).valid?
  end

  test "requires a city" do
    tour = Tour.new(number: 5, city: nil)
    assert_not tour.valid?
    assert_includes tour.errors[:city], "must exist"
  end

  test "number is unique within a city but reusable across cities" do
    duplicate = Tour.new(number: tours(:tour_one).number, city: cities(:moscow))
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:number], "has already been taken"

    other_city = Tour.new(number: tours(:tour_one).number, city: cities(:spb))
    assert other_city.valid?, other_city.errors.full_messages.to_sentence
  end

  test "format must be a known game format" do
    tour = Tour.new(number: 5, city: cities(:moscow), format: "unknown")
    assert_not tour.valid?
    assert_includes tour.errors[:format], "is not included in the list"
  end

  test "defaults to mother of dragons format" do
    tour = Tour.create!(number: 5, city: cities(:moscow))
    assert_equal "mother_of_dragons", tour.format
    assert_equal GameFormat.find("mother_of_dragons"), tour.game_format
  end

  test "number range follows the format tour count" do
    classic = Tour.new(number: 7, city: cities(:spb), format: "classic")
    assert_not classic.valid?
    assert_includes classic.errors[:number].join, "Классика"

    classic.number = 6
    assert classic.valid?, classic.errors.full_messages.to_sentence
  end

  test "mother of dragons allows up to eight tours" do
    mod = Tour.new(number: 8, city: cities(:moscow), format: "mother_of_dragons")
    assert mod.valid?, mod.errors.full_messages.to_sentence

    mod.number = 9
    assert_not mod.valid?
  end

  test "final tour follows the selected format tour count" do
    assert Tour.new(number: 8, format: "mother_of_dragons").final_tour?
    assert Tour.new(number: 6, format: "classic").final_tour?
    assert_not Tour.new(number: 7, format: "mother_of_dragons").final_tour?
  end

  test "house reuse is allowed only in the final mother of dragons tour" do
    assert Tour.new(number: 8, format: "mother_of_dragons").allows_house_reuse?
    assert_not Tour.new(number: 7, format: "mother_of_dragons").allows_house_reuse?
    assert_not Tour.new(number: 6, format: "classic").allows_house_reuse?
  end

  test "date range label shows a single date when the dates match" do
    tour = Tour.new(
      starts_on: Date.new(2026, 9, 13),
      ends_on: Date.new(2026, 9, 13)
    )

    assert_equal "13.09", tour.date_range_label
  end

  test "date range label shows both dates when they differ" do
    tour = Tour.new(
      starts_on: Date.new(2026, 9, 13),
      ends_on: Date.new(2026, 9, 14)
    )

    assert_equal "13.09 – 14.09", tour.date_range_label
  end

  test "tables_count is bounded by the available table letters" do
    tour = Tour.new(number: 5, city: cities(:moscow))
    tour.tables_count = 0
    assert_not tour.valid?
    tour.tables_count = Game::TABLE_LETTERS.size + 1
    assert_not tour.valid?
    tour.tables_count = 3
    assert tour.valid?, tour.errors.full_messages.to_sentence
  end

  test "table_letters reflects tables_count" do
    tour = Tour.new(tables_count: 1)
    assert_equal %w[A], tour.table_letters
    tour.tables_count = 3
    assert_equal %w[A B C], tour.table_letters
  end

  test "sync_tables creates missing tables and removes empty extras" do
    tour = Tour.create!(number: 5, city: cities(:moscow), tables_count: 2)
    tour.sync_tables
    assert_equal %w[A B], tour.games.order(:table_letter).pluck(:table_letter)

    tour.update!(tables_count: 4)
    tour.sync_tables
    assert_equal %w[A B C D], tour.games.order(:table_letter).pluck(:table_letter)

    tour.update!(tables_count: 1)
    tour.sync_tables
    assert_equal %w[A], tour.games.order(:table_letter).pluck(:table_letter)
  end

  test "sync_tables keeps extra tables that already have results" do
    tour = Tour.create!(number: 5, city: cities(:moscow), tables_count: 2)
    tour.sync_tables
    game_b = tour.games.find_by!(table_letter: "B")
    player = Player.create!(first_name: "Стол", nickname: "@table_keeper")
    GameResult.create!(game: game_b, player: player, house: "stark", place: 1, points: 12, capitals: 0, dragons: 0, castles: 0)

    tour.update!(tables_count: 1)
    tour.sync_tables

    assert_includes tour.games.pluck(:table_letter), "B", "стол с результатами не должен удаляться"
  end
end
