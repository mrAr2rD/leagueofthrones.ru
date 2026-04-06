require "test_helper"

class PlayerTest < ActiveSupport::TestCase
  test "valid player" do
    player = Player.new(first_name: "Test", nickname: "tester")
    assert player.valid?
  end

  test "valid player with last_name" do
    player = Player.new(first_name: "Test", last_name: "Player", nickname: "tester2")
    assert player.valid?
  end

  test "new players participate in tournament by default" do
    assert Player.new.participates_in_tournament?
  end

  test "legacy nil tournament flag is treated as participating" do
    player = Player.new(first_name: "Legacy", nickname: "legacy_nil", participates_in_tournament: nil)
    assert player.participates_in_tournament?
  end

  test "database default marks inserted players as participating" do
    Player.insert_all!([ {
      first_name: "Legacy DB",
      nickname: "@legacy_db_default",
      created_at: Time.current,
      updated_at: Time.current
    } ])

    assert Player.find_by!(nickname: "@legacy_db_default").participates_in_tournament?
  end

  test "requires first_name" do
    player = Player.new(nickname: "tester")
    assert_not player.valid?
  end

  test "requires unique nickname" do
    player = Player.new(first_name: "Another", nickname: players(:daenerys).nickname)
    assert_not player.valid?
  end

  test "display_name without last_name" do
    assert_equal "Семён", players(:daenerys).display_name
  end

  test "display_name with last_name" do
    player = Player.new(first_name: "Иван", last_name: "Иванов", nickname: "test")
    assert_equal "Иван Иванов", player.display_name
  end

  test "admin option label includes nickname" do
    assert_equal "Семён (@samzakharov)", players(:daenerys).admin_option_label
  end

  test "initials without last_name" do
    assert_equal "С", players(:daenerys).initials
  end

  test "initials with last_name" do
    player = Player.new(first_name: "Иван", last_name: "Иванов")
    assert_equal "ИИ", player.initials
  end
end
