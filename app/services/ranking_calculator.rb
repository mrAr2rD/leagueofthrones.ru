class RankingCalculator
  RankedPlayer = Struct.new(
    :player, :total_points, :best6_points, :wins, :capitals, :dragons,
    :games_played, :rank, :league, :rank_change, keyword_init: true
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
    players = Player.includes(game_results: :game).all
    ranked = players.map { |player| build_ranking(player) }

    ranked.sort_by! { |rp| [ -rp.best6_points, -rp.wins, -rp.capitals, -rp.dragons ] }

    ranked.each_with_index do |rp, idx|
      rp.rank = idx + 1
      rp.league = league_for(rp.rank)
      rp.rank_change = rank_change(rp.player.previous_rank, rp.rank)
    end

    ranked
  end

  private

  def build_ranking(player)
    results = player.game_results.select { |gr| gr.points.present? }
    points_list = results.map(&:points).sort.reverse
    best6 = points_list.first(6).sum

    RankedPlayer.new(
      player: player,
      total_points: points_list.sum,
      best6_points: best6,
      wins: results.count { |r| r.place == 1 },
      capitals: results.sum(&:capitals),
      dragons: results.sum(&:dragons),
      games_played: results.size,
      rank: 0,
      league: :iron,
      rank_change: nil
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
