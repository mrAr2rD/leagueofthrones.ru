require "test_helper"

class CityTest < ActiveSupport::TestCase
  test "to_param returns the slug" do
    assert_equal "moscow", cities(:moscow).to_param
  end

  test "rejects an invalid slug" do
    city = City.new(name: "Тест", slug: "Bad Slug", default_format: "classic")
    assert_not city.valid?
    assert_includes city.errors[:slug].join, "латиница"
  end

  test "default_game_format resolves from the format key" do
    assert_equal GameFormat.find("classic"), cities(:spb).default_game_format
  end

  test "auto-creates a rules page on creation" do
    city = City.create!(name: "Казань", slug: "kazan", default_format: "classic")

    rules = city.site_pages.find_by(slug: "rules")
    assert_not_nil rules
    assert_equal "Регламент турнира", rules.title
  end
end
