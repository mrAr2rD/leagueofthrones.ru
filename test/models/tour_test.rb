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
end
