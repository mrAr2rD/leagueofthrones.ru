require "test_helper"

class RankingCalculatorTest < ActiveSupport::TestCase
  setup do
    tours(:tour_one).update!(played: true)
  end

  test "returns ranked players" do
    rankings = RankingCalculator.call
    assert_kind_of Array, rankings
    assert rankings.all? { |rp| rp.is_a?(RankingCalculator::RankedPlayer) }
  end

  test "ranks are assigned 1 to N" do
    rankings = RankingCalculator.call
    assert_equal (1..rankings.size).to_a, rankings.map(&:rank)
  end

  test "sorted by best6_points descending" do
    rankings = RankingCalculator.call
    points = rankings.map(&:best6_points)
    assert_equal points, points.sort.reverse
  end

  test "assigns leagues correctly" do
    rankings = RankingCalculator.call
    first = rankings.first
    assert_includes [ :gold, :silver, :bronze, :iron ], first.league
  end

  test "recalculate! updates previous_rank" do
    RankingCalculator.recalculate!
    daenerys = players(:daenerys).reload
    assert_not_nil daenerys.previous_rank
  end

  test "rank_change calculated after recalculate" do
    RankingCalculator.recalculate!
    rankings = RankingCalculator.call
    daenerys_ranking = rankings.find { |rp| rp.player.id == players(:daenerys).id }
    assert_not_nil daenerys_ranking.rank_change
  end

  test "leaderboard uses saved game_result points and keeps only the best six games" do
    player = Player.create!(first_name: "Лидерборд", nickname: "@leaderboard_case")
    houses = GameResult::HOUSE_LABELS.keys
    tours = [ tours(:tour_two) ] +
      (3..8).map do |number|
        Tour.create!(number: number, played: true, played_on: Date.new(2026, 1, number))
      end

    tours(:tour_two).update!(played: true)

    tours.each_with_index do |tour, index|
      game = Game.create!(tour: tour, table_letter: index.even? ? "A" : "B")
      suggested_points = GameResult.calculate_points(
        place: index + 1,
        capitals: [ index % 4, GameResult::MAX_CAPITAL_POINTS ].min,
        dragons: index % 3,
        castles: [ index % 6, GameResult::MAX_CASTLES_POINTS ].min,
        table_letter: game.table_letter
      )

      GameResult.create!(
        game: game,
        player: player,
        house: houses[index],
        place: index + 1,
        capitals: [ index % 4, GameResult::MAX_CAPITAL_POINTS ].min,
        dragons: index % 3,
        castles: [ index % 6, GameResult::MAX_CASTLES_POINTS ].min,
        points: index.zero? ? suggested_points + 5 : suggested_points
      )
    end

    rankings = RankingCalculator.call
    player_ranking = rankings.find { |rp| rp.player.id == player.id }
    all_points = player.game_results.order(:id).pluck(:points).sort.reverse
    latest_result = player.game_results.joins(game: :tour).order("tours.number DESC").first

    assert_equal all_points.sum, player_ranking.total_points
    assert_equal all_points.first(6).sum, player_ranking.best6_points
    assert_equal latest_result.points, player_ranking.last_tour_points
  end
end
