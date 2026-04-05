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
    played_tours = [ tours(:tour_two) ] +
      (3..8).map do |number|
        Tour.create!(number: number, played: true, played_on: Date.new(2026, 1, number))
      end

    tours(:tour_two).update!(played: true)

    played_tours.each_with_index do |tour, index|
      game = Game.create!(tour: tour, table_letter: index.even? ? "A" : "B")
      capital_captures = index.even? ? (index % 3) : nil
      capital_controls = index.even? ? 1 : nil
      legacy_capitals = index.odd? ? [ index % 4, GameResult::MAX_CAPITAL_POINTS ].min : 0
      suggested_points = GameResult.calculate_points(
        place: index + 1,
        capitals: legacy_capitals,
        capital_captures: capital_captures,
        capital_controls: capital_controls,
        dragons: index % 3,
        castles: [ index % 6, GameResult::MAX_CASTLES_POINTS ].min,
        table_letter: game.table_letter
      )

      GameResult.create!(
        game: game,
        player: player,
        house: houses[index],
        place: index + 1,
        capitals: legacy_capitals,
        capital_captures: capital_captures,
        capital_controls: capital_controls,
        lands: 10 + index,
        skulls: index % 2,
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

  test "higher wins break ties on equal best6 points" do
    player_with_win = create_ranked_player(
      nickname: "@wins_first",
      place: 1,
      points: 20
    )
    player_without_win = create_ranked_player(
      nickname: "@wins_second",
      place: 2,
      points: 20
    )

    assert_operator ranking_for(player_with_win).rank, :<, ranking_for(player_without_win).rank
  end

  test "higher captures break ties after equal points and wins" do
    player_with_more_captures = create_ranked_player(
      nickname: "@captures_first",
      place: 1,
      points: 20,
      capitals: 2
    )
    player_with_fewer_captures = create_ranked_player(
      nickname: "@captures_second",
      place: 1,
      points: 20,
      capitals: 1
    )

    assert_equal 2, ranking_for(player_with_more_captures).captures
    assert_equal 1, ranking_for(player_with_fewer_captures).captures
    assert_operator ranking_for(player_with_more_captures).rank, :<, ranking_for(player_with_fewer_captures).rank
  end

  test "capital controls do not affect ranking order" do
    player_with_more_controls = create_ranked_player(
      nickname: "@controls_ignored",
      place: 1,
      points: 20,
      capital_captures: 1,
      capital_controls: 5
    )
    player_with_more_captures = create_ranked_player(
      nickname: "@captures_count",
      place: 1,
      points: 20,
      capital_captures: 2,
      capital_controls: 0
    )

    assert_equal 1, ranking_for(player_with_more_controls).captures
    assert_equal 2, ranking_for(player_with_more_captures).captures
    assert_operator ranking_for(player_with_more_captures).rank, :<, ranking_for(player_with_more_controls).rank
  end

  test "higher dragons break ties after equal points wins and captures" do
    player_with_more_dragons = create_ranked_player(
      nickname: "@dragons_first",
      place: 1,
      points: 20,
      capitals: 1,
      dragons: 2
    )
    player_with_fewer_dragons = create_ranked_player(
      nickname: "@dragons_second",
      place: 1,
      points: 20,
      capitals: 1,
      dragons: 1
    )

    assert_operator ranking_for(player_with_more_dragons).rank, :<, ranking_for(player_with_fewer_dragons).rank
  end

  test "higher lands break ties after equal points wins captures and dragons" do
    player_with_more_lands = create_ranked_player(
      nickname: "@lands_first",
      place: 1,
      points: 20,
      capitals: 1,
      dragons: 1,
      lands: 5
    )
    player_with_fewer_lands = create_ranked_player(
      nickname: "@lands_second",
      place: 1,
      points: 20,
      capitals: 1,
      dragons: 1,
      lands: 3
    )

    assert_equal 5, ranking_for(player_with_more_lands).lands
    assert_equal 3, ranking_for(player_with_fewer_lands).lands
    assert_operator ranking_for(player_with_more_lands).rank, :<, ranking_for(player_with_fewer_lands).rank
  end

  test "fixture data ranks by lands when earlier tie breakers are equal" do
    tours(:tour_two).update!(played: true)

    higher_lands_ranking = ranking_for(players(:arya))
    lower_lands_ranking = ranking_for(players(:sansa))

    assert_equal 20, higher_lands_ranking.best6_points
    assert_equal 20, lower_lands_ranking.best6_points
    assert_equal 1, higher_lands_ranking.wins
    assert_equal 1, lower_lands_ranking.wins
    assert_equal 1, higher_lands_ranking.captures
    assert_equal 1, lower_lands_ranking.captures
    assert_equal 1, higher_lands_ranking.dragons
    assert_equal 1, lower_lands_ranking.dragons
    assert_equal 6, higher_lands_ranking.lands
    assert_equal 4, lower_lands_ranking.lands
    assert_operator higher_lands_ranking.rank, :<, lower_lands_ranking.rank
  end

  test "legacy capitals participate in captures tie break" do
    legacy_player = create_ranked_player(
      nickname: "@legacy_captures",
      place: 1,
      points: 20,
      capitals: 2
    )
    split_player = create_ranked_player(
      nickname: "@split_captures",
      place: 1,
      points: 20,
      capital_captures: 1,
      capital_controls: 9
    )

    assert_equal 2, ranking_for(legacy_player).captures
    assert_equal 1, ranking_for(split_player).captures
    assert_operator ranking_for(legacy_player).rank, :<, ranking_for(split_player).rank
  end

  private

  def ranking_for(player)
    RankingCalculator.call.find { |rp| rp.player.id == player.id }
  end

  def create_ranked_player(nickname:, place:, points:, capitals: 0, capital_captures: nil, capital_controls: nil, dragons: 0, lands: 0)
    player = Player.create!(first_name: "Тайбрейк", nickname: nickname)
    create_ranked_result(
      tour: create_played_tour,
      player: player,
      house: next_house,
      place: place,
      points: points,
      capitals: capitals,
      capital_captures: capital_captures,
      capital_controls: capital_controls,
      dragons: dragons,
      lands: lands
    )
    player
  end

  def create_played_tour
    @tour_sequence ||= Tour.maximum(:number).to_i
    @tour_sequence += 1
    Tour.create!(
      number: @tour_sequence,
      played: true,
      played_on: Date.new(2026, 3, 1) + @tour_sequence
    )
  end

  def next_house
    @house_index ||= 0
    house = GameResult::HOUSE_LABELS.keys.fetch(@house_index % GameResult::HOUSE_LABELS.size)
    @house_index += 1
    house
  end

  def create_ranked_result(tour:, player:, house:, place:, points:, capitals:, capital_captures: nil, capital_controls: nil, dragons: 0, lands: 0)
    table_letter = Game::TABLE_LETTERS.find { |letter| !tour.games.exists?(table_letter: letter) }
    game = Game.create!(tour: tour, table_letter: table_letter)

    GameResult.create!(
      game: game,
      player: player,
      house: house,
      place: place,
      points: points,
      capitals: capitals,
      capital_captures: capital_captures,
      capital_controls: capital_controls,
      lands: lands,
      dragons: dragons,
      castles: 0
    )
  end
end
