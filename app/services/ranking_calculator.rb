class RankingCalculator
  RankedPlayer = Struct.new(
    :player, :total_points, :best6_points, :wins, :captures, :dragons, :lands,
    :games_played, :rank, :league, :rank_change, :last_tour_points, keyword_init: true
  )

  # Цвет и название лиг постоянны; границы рангов зависят от формата города
  # (размер дивизиона = число игроков за столом) — см. #league_for.
  LEAGUES = {
    gold:   { color: "#FFD700", label: "Золотая" },
    silver: { color: "#C0C0C0", label: "Серебряная" },
    bronze: { color: "#CD7F32", label: "Бронзовая" },
    iron:   { color: "#4B4B4B", label: "Железная" }
  }.freeze

  LEAGUE_ORDER = %i[gold silver bronze iron].freeze

  def self.call(city)
    new(city).call
  end

  def self.recalculate!(city)
    rankings = call(city)
    # Прежний ранг хранится отдельно по каждому городу (player_cities),
    # чтобы «прирост» не смешивался между городами.
    PlayerCity.transaction do
      rankings.each do |rp|
        city.player_cities.where(player_id: rp.player.id).update_all(previous_rank: rp.rank)
      end
    end
    rankings
  end

  def initialize(city)
    @city = city
  end

  def call
    players = @city.players.participating_in_tournament.includes(game_results: { game: :tour })
    @tier = @city.default_game_format.league_tier_size
    @played_tour_ids = @city.tours.played.pluck(:id).to_set
    @last_tour = @city.tours.played.order(number: :desc).first
    # Прежний ранг — свой в каждом городе (player_cities.previous_rank).
    @previous_ranks = @city.player_cities.pluck(:player_id, :previous_rank).to_h
    ranked = players.map { |player| build_ranking(player) }

    ranked.sort_by! { |rp| [ -rp.best6_points, -rp.wins, -rp.captures, -rp.dragons, -rp.lands ] }

    ranked.each_with_index do |rp, idx|
      rp.rank = idx + 1
      rp.league = league_for(rp.rank)
      rp.rank_change = rank_change(@previous_ranks[rp.player.id], rp.rank)
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
    index = (rank - 1) / @tier
    LEAGUE_ORDER.fetch([ index, LEAGUE_ORDER.size - 1 ].min)
  end

  def rank_change(previous, current)
    return nil if previous.nil?
    previous - current # positive = improved, negative = dropped
  end
end
