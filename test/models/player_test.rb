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

  test "initials without last_name" do
    assert_equal "С", players(:daenerys).initials
  end

  test "initials with last_name" do
    player = Player.new(first_name: "Иван", last_name: "Иванов")
    assert_equal "ИИ", player.initials
  end
end
