require "test_helper"

class RankingCalculatorTest < ActiveSupport::TestCase
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
end
