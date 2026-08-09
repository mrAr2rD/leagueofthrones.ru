require "test_helper"

class TidesOfBattleSessionTest < ActiveSupport::TestCase
  test "uses the official 24-card deck distribution" do
    assert_equal 24, TidesOfBattleSession::DECK.size
    assert_equal(
      {
        "zero" => 8,
        "skull" => 2,
        "sword" => 4,
        "fortification" => 4,
        "two" => 4,
        "three" => 2
      },
      TidesOfBattleSession::DECK.tally
    )
  end

  test "creates an isolated token and shuffled deck" do
    first = cities(:moscow).tides_of_battle_sessions.create!
    second = cities(:moscow).tides_of_battle_sessions.create!

    assert_not_equal first.token, second.token
    assert_equal TidesOfBattleSession::DECK.tally, first.deck_order.tally
    assert_equal 24, first.deck_order.size
  end

  test "draws once for each side without replacement" do
    battle = create_battle(deck_order: %w[skull sword two])

    battle.draw!(:attacker)
    battle.draw!(:attacker)
    battle.draw!(:defender)

    assert_equal "skull", battle.attacker_card
    assert_equal "sword", battle.defender_card
    assert_equal [ "two" ], battle.deck_order
  end

  test "allows only one reroll after both cards are drawn" do
    battle = create_battle(deck_order: %w[skull sword three zero])
    battle.draw!(:attacker)
    battle.draw!(:defender)

    battle.reroll!(:attacker)

    assert_equal "three", battle.attacker_card
    assert_equal "attacker", battle.rerolled_side
    assert_equal [ "zero" ], battle.deck_order
    assert_not battle.reroll_available?

    error = assert_raises(TidesOfBattleSession::InvalidTransition) do
      battle.reroll!(:defender)
    end
    assert_equal "Валирийский меч уже использован", error.message
  end

  test "does not allow a reroll before both cards are drawn" do
    battle = create_battle(deck_order: %w[skull sword three])
    battle.draw!(:attacker)

    assert_raises(TidesOfBattleSession::InvalidTransition) do
      battle.reroll!(:attacker)
    end
  end

  test "reveals only after both sides have drawn" do
    battle = create_battle(deck_order: %w[zero three])
    battle.draw!(:attacker)

    assert_raises(TidesOfBattleSession::InvalidTransition) { battle.reveal! }

    battle.draw!(:defender)
    battle.reveal!

    assert battle.revealed?
    assert_not_nil battle.revealed_at
    assert_raises(TidesOfBattleSession::InvalidTransition) do
      battle.reroll!(:attacker)
    end
  end

  test "returns presentation data for the drawn card" do
    battle = create_battle(deck_order: %w[fortification])
    battle.draw!(:attacker)

    assert_equal(
      { strength: 1, symbol: "fortification", label: "Укрепление" },
      battle.card_for(:attacker)
    )
  end

  private

  def create_battle(deck_order:)
    cities(:moscow).tides_of_battle_sessions.create!(deck_order: deck_order)
  end
end
