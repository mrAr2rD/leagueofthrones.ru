require "test_helper"

class TidesOfBattleSessionsControllerTest < ActionDispatch::IntegrationTest
  test "opening the tool creates a new isolated battle session" do
    assert_difference "TidesOfBattleSession.count", 1 do
      get city_tides_of_battle_url(cities(:moscow))
    end

    battle = TidesOfBattleSession.order(:created_at).last
    assert_redirected_to city_tides_of_battle_session_url(cities(:moscow), battle.token)

    follow_redirect!
    assert_response :success
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_select "[data-testid=attacker-zone]"
    assert_select "[data-testid=defender-zone]"
    assert_select "a[href=?]", city_tides_of_battle_beta_path(cities(:moscow)), text: "Бета версия"
  end

  test "keeps both drawn cards hidden" do
    battle = create_battle(deck_order: %w[skull sword two])
    battle.draw!(:attacker)
    battle.draw!(:defender)

    get battle_url(battle)

    assert_response :success
    assert_select "[data-testid=attacker-card-back]", count: 1
    assert_select "[data-testid=defender-card-back]", count: 1
    assert_select "[data-testid$='-card-face']", count: 0
  end

  test "peeking shows only the selected player's card" do
    battle = create_battle(deck_order: %w[skull sword two])
    battle.draw!(:attacker)
    battle.draw!(:defender)

    post city_tides_of_battle_peek_url(cities(:moscow), battle.token, :attacker)

    assert_response :success
    assert_select "[data-testid=attacker-card-face]", count: 1
    assert_select "[data-testid=defender-card-face]", count: 0
    assert_select "[data-testid=defender-card-back]", count: 1
  end

  test "reroll replaces one card and returns to the hidden state" do
    battle = create_battle(deck_order: %w[skull sword three zero])
    battle.draw!(:attacker)
    battle.draw!(:defender)

    post city_tides_of_battle_reroll_url(cities(:moscow), battle.token, :attacker)

    assert_redirected_to battle_url(battle)
    assert_equal "three", battle.reload.attacker_card
    assert_equal "attacker", battle.rerolled_side

    follow_redirect!
    assert_select "[data-testid=attacker-card-back]", count: 1
    assert_select "[data-testid=defender-card-back]", count: 1
    assert_select "[data-testid$='-card-face']", count: 0
  end

  test "final reveal shows both cards" do
    battle = create_battle(deck_order: %w[zero three])
    battle.draw!(:attacker)
    battle.draw!(:defender)

    post city_tides_of_battle_reveal_url(cities(:moscow), battle.token)

    assert_redirected_to battle_url(battle)
    follow_redirect!
    assert_select "[data-testid=attacker-card-face]", count: 1
    assert_select "[data-testid=defender-card-face]", count: 1
    assert_select "a", text: "Новый бой"
  end

  test "different battle sessions do not affect one another" do
    first = create_battle(deck_order: %w[skull sword])
    second = create_battle(deck_order: %w[three zero])

    post city_tides_of_battle_draw_url(cities(:moscow), first.token, :attacker)

    assert_equal "skull", first.reload.attacker_card
    assert_nil second.reload.attacker_card
    assert_equal %w[three zero], second.deck_order
  end

  test "a battle session cannot be opened through another city" do
    battle = create_battle(deck_order: %w[zero three])

    get city_tides_of_battle_session_url(cities(:spb), battle.token)

    assert_response :not_found
  end

  test "rejects an unknown battle side" do
    battle = create_battle(deck_order: %w[zero three])

    post city_tides_of_battle_draw_url(cities(:moscow), battle.token, :spectator)

    assert_response :not_found
    assert_nil battle.reload.attacker_card
    assert_nil battle.defender_card
  end

  private

  def create_battle(deck_order:)
    cities(:moscow).tides_of_battle_sessions.create!(deck_order: deck_order)
  end

  def battle_url(battle)
    city_tides_of_battle_session_url(cities(:moscow), battle.token)
  end
end
