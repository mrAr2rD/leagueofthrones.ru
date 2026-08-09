require "test_helper"

class TidesOfBattleBetaSessionsControllerTest < ActionDispatch::IntegrationTest
  test "opening beta creates a session and stays on the beta URL" do
    assert_difference "TidesOfBattleSession.count", 1 do
      get city_tides_of_battle_beta_url(cities(:moscow))
    end

    battle = TidesOfBattleSession.order(:created_at).last
    assert_redirected_to city_tides_of_battle_beta_session_url(cities(:moscow), battle.token)

    follow_redirect!
    assert_response :success
    assert_select "[data-testid=tides-beta-arena]"
    assert_select "[data-controller=tides-reel]", count: 2
    assert_select "[data-testid$='-spin-overlay']", count: 2
    assert_select ".tides-beta-case-window", count: 2
    assert_select ".tides-beta-case-pointer", count: 2
    assert_select ".tides-beta-reel-track .tides-beta-case-card", count: 48
  end

  test "beta JSON draw returns the exact persisted card for the reel target" do
    battle = create_battle(deck_order: %w[fortification three zero])

    post city_tides_of_battle_beta_draw_url(cities(:moscow), battle.token, :attacker), as: :json

    assert_response :success
    payload = response.parsed_body
    assert_equal "fortification", battle.reload.attacker_card
    assert_equal(
      {
        "key" => "fortification",
        "strength" => 1,
        "symbol" => "fortification",
        "label" => "Укрепление"
      },
      payload.fetch("card")
    )
    assert_equal city_tides_of_battle_beta_session_path(
      cities(:moscow),
      battle.token,
      preview: :attacker
    ), payload.fetch("preview_url")
  end

  test "beta draw previews the result and the clean URL keeps it hidden" do
    battle = create_battle(deck_order: %w[skull sword two])

    post city_tides_of_battle_beta_draw_url(cities(:moscow), battle.token, :attacker)

    assert_redirected_to city_tides_of_battle_beta_session_url(
      cities(:moscow),
      battle.token,
      preview: :attacker
    )
    assert_equal "skull", battle.reload.attacker_card

    follow_redirect!
    assert_select "[data-testid=attacker-card-face]", count: 1
    assert_select "[data-testid=attacker-auto-hide]", count: 1
    assert_select "[data-controller=tides-auto-hide]", count: 1

    get beta_battle_url(battle)
    assert_select "[data-testid=attacker-card-back]", count: 1
    assert_select "[data-testid=attacker-card-face]", count: 0
  end

  test "beta peek reveals only the selected side" do
    battle = create_battle(deck_order: %w[skull sword two])
    battle.draw!(:attacker)
    battle.draw!(:defender)

    post city_tides_of_battle_beta_peek_url(cities(:moscow), battle.token, :attacker)

    assert_response :success
    assert_select "[data-testid=attacker-card-face]", count: 1
    assert_select "[data-testid=defender-card-face]", count: 0
    assert_select "form[action=?]", city_tides_of_battle_beta_reroll_path(cities(:moscow), battle.token, :attacker)
  end

  test "beta reroll uses the remaining deck and previews only the replacement" do
    battle = create_battle(deck_order: %w[skull sword three zero])
    battle.draw!(:attacker)
    battle.draw!(:defender)

    post city_tides_of_battle_beta_reroll_url(cities(:moscow), battle.token, :attacker)

    assert_redirected_to city_tides_of_battle_beta_session_url(
      cities(:moscow),
      battle.token,
      preview: :attacker
    )
    assert_equal "three", battle.reload.attacker_card
    assert_equal "sword", battle.defender_card
    assert_equal [ "zero" ], battle.deck_order

    follow_redirect!
    assert_select "[data-testid=attacker-card-face]", count: 1
    assert_select "[data-testid=defender-card-face]", count: 0

    get beta_battle_url(battle)
    assert_select "[data-testid=attacker-card-back]", count: 1
    assert_select "[data-testid=defender-card-back]", count: 1
    assert_select "[data-testid$='-card-face']", count: 0
  end

  test "beta JSON reroll returns the replacement while preserving the opponent card" do
    battle = create_battle(deck_order: %w[skull sword three zero])
    battle.draw!(:attacker)
    battle.draw!(:defender)

    post city_tides_of_battle_beta_reroll_url(cities(:moscow), battle.token, :attacker), as: :json

    assert_response :success
    payload = response.parsed_body
    assert_equal "three", battle.reload.attacker_card
    assert_equal "sword", battle.defender_card
    assert_equal "three", payload.dig("card", "key")
    assert_equal 3, payload.dig("card", "strength")
    assert_nil payload.dig("card", "symbol")
  end

  test "beta final reveal stays on beta and starts another beta battle" do
    battle = create_battle(deck_order: %w[zero three])
    battle.draw!(:attacker)
    battle.draw!(:defender)

    post city_tides_of_battle_beta_reveal_url(cities(:moscow), battle.token)

    assert_redirected_to beta_battle_url(battle)
    follow_redirect!
    assert_select "[data-testid=attacker-card-face]", count: 1
    assert_select "[data-testid=defender-card-face]", count: 1
    assert_select "a[href=?]", city_tides_of_battle_beta_path(cities(:moscow)), text: "Новый бой BETA"
  end

  private

  def create_battle(deck_order:)
    cities(:moscow).tides_of_battle_sessions.create!(deck_order: deck_order)
  end

  def beta_battle_url(battle)
    city_tides_of_battle_beta_session_url(cities(:moscow), battle.token)
  end
end
