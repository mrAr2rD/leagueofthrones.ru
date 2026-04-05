require "test_helper"

class PlayersControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get player_url(players(:daenerys))
    assert_response :success
    assert_match "Семён", response.body
  end

  test "show uses captures wording and ranking captures values" do
    player = Player.create!(first_name: "Профиль", nickname: "@profile_captures")
    tour = tours(:tour_two)
    game = Game.create!(tour: tour, table_letter: "A")

    GameResult.create!(
      game: game,
      player: player,
      house: "stark",
      place: 1,
      points: 20,
      capitals: 99,
      capital_captures: 1,
      capital_controls: 2,
      dragons: 0,
      castles: 0
    )

    get player_url(player)
    assert_response :success
    assert_match "Захваты", response.body
    assert_no_match "Столицы", response.body

    document = Nokogiri::HTML(response.body)
    summary_cards = document.css(".player-summary-item").map { |node| node.text.squish }
    history_row = document.css("table.player-stats-table tbody tr td").map { |node| node.text.squish }

    assert_includes summary_cards, "1 Захваты"
    assert_equal "1", history_row[4]
  end
end
