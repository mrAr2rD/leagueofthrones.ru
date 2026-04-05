require "test_helper"
require "date"

class PlayersControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get player_url(players(:daenerys))
    assert_response :success
    assert_match "Семён", response.body
  end

  test "show uses captures wording and history values" do
    player = Player.create!(first_name: "Профиль", nickname: "@profile_captures")
    tour = tours(:tour_two)
    game = Game.create!(tour: tour, table_letter: "A")
    extra_tour = Tour.create!(number: 3, played: true, played_on: Date.new(2026, 1, 21))
    extra_game = Game.create!(tour: extra_tour, table_letter: "A")

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
      castles: 4
    )

    GameResult.create!(
      game: extra_game,
      player: player,
      house: "targaryen",
      place: 2,
      points: 10,
      capitals: 0,
      dragons: 1,
      castles: 2
    )

    get player_url(player)
    assert_response :success
    assert_match "Дом", response.body
    assert_match "Захваты", response.body
    assert_match "icon-capture", response.body
    assert_no_match "Столицы", response.body

    document = Nokogiri::HTML(response.body)
    summary_cards = document.css(".player-summary-item").map { |node| node.text.squish }
    history_rows = document.css("table.player-stats-table tbody tr").map do |row|
      row.css("td").map { |node| node.text.squish }
    end

    assert_includes summary_cards, "1 Захваты"
    assert_equal [ "2", "A", "Старк" ], history_rows.first.first(3)
    assert_equal "1", history_rows.first[5]
    assert_equal "4", history_rows.first[7]
    assert_equal [ "3", "A", "Таргариен" ], history_rows.second.first(3)
    assert_equal "2", history_rows.second[7]
  end
end
