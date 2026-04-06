class RankingCalculator
  RankedPlayer = Struct.new(
    :player, :total_points, :best6_points, :wins, :captures, :dragons, :lands,
    :games_played, :rank, :league, :rank_change, :last_tour_points, keyword_init: true
  )

  LEAGUES = {
    gold:   { range: 1..8,   color: "#FFD700", label: "Золотая" },
    silver: { range: 9..16,  color: "#C0C0C0", label: "Серебряная" },
    bronze: { range: 17..24, color: "#CD7F32", label: "Бронзовая" },
    iron:   { range: 25..32, color: "#4B4B4B", label: "Железная" }
  }.freeze

  def self.call
    new.call
  end

  def self.recalculate!
    rankings = call
    Player.transaction do
      rankings.each do |rp|
        rp.player.update_column(:previous_rank, rp.rank)
      end
    end
    rankings
  end

  def call
    players = Player.participating_in_tournament.includes(game_results: { game: :tour })
    @played_tour_ids = Tour.played.pluck(:id).to_set
    @last_tour = Tour.played.order(number: :desc).first
    ranked = players.map { |player| build_ranking(player) }

    ranked.sort_by! { |rp| [ -rp.best6_points, -rp.wins, -rp.captures, -rp.dragons, -rp.lands ] }

    ranked.each_with_index do |rp, idx|
      rp.rank = idx + 1
      rp.league = league_for(rp.rank)
      rp.rank_change = rank_change(rp.player.previous_rank, rp.rank)
    end

    ranked
  end

  private

  def build_ranking(player)
    results = player.game_results.select { |gr| gr.points.present? && @played_tour_ids.include?(gr.game.tour_id) }
    points_list = results.map(&:points).sort.reverse
    best6 = points_list.first(6).sum

    last_tour_pts = if @last_tour
      results.select { |r| r.game.tour_id == @last_tour.id }
             .sum { |r| r.points || 0 }
    end

    RankedPlayer.new(
      player: player,
      total_points: points_list.sum,
      best6_points: best6,
      wins: results.count { |r| r.place == 1 },
      captures: results.sum(&:ranking_captures),
      dragons: results.sum { |r| r.dragons || 0 },
      lands: results.sum { |r| r.lands || 0 },
      games_played: results.size,
      rank: 0,
      league: :iron,
      rank_change: nil,
      last_tour_points: last_tour_pts
    )
  end

  def league_for(rank)
    LEAGUES.each do |key, config|
      return key if config[:range].cover?(rank)
    end
    :iron
  end

  def rank_change(previous, current)
    return nil if previous.nil?
    previous - current # positive = improved, negative = dropped
  end
end
