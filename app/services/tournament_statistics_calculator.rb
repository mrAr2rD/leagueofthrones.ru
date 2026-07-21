class TournamentStatisticsCalculator
  PlayerStatistics = Struct.new(
    :player,
    :games_count,
    :captures,
    :dragons,
    :skulls,
    keyword_init: true
  )

  Nomination = Struct.new(
    :definition,
    :max_value,
    :leaders,
    keyword_init: true
  )

  Result = Struct.new(
    :city,
    :game_format,
    :played_tours_count,
    :games_count,
    :rows,
    :nominations,
    :problems,
    keyword_init: true
  ) do
    def complete?
      problems.empty?
    end

    def nomination(key)
      nominations.find { |item| item.definition.key == key.to_s }
    end
  end

  class << self
    def call(city:, format:)
      new(city: city, format: format).call
    end
  end

  def initialize(city:, format:)
    @city = city
    @game_format = format.is_a?(GameFormat) ? format : GameFormat::FORMATS.fetch(format.to_s)
  end

  def call
    tours = load_tours
    problems = completeness_problems(tours)
    rows = aggregate_rows(tours)

    Result.new(
      city: @city,
      game_format: @game_format,
      played_tours_count: tours.size,
      games_count: tours.sum { |tour| tour.table_letters.size },
      rows: rows,
      nominations: build_nominations(rows),
      problems: problems
    )
  end

  private

  def load_tours
    Tour.where(city: @city, format: @game_format.key)
        .played
        .order(:number)
        .includes(games: { game_results: :player })
        .to_a
  end

  def aggregate_rows(tours)
    statistics = {}

    tours.each do |tour|
      tour.games.each do |game|
        game.game_results.each do |result|
          next unless result.player

          row = statistics[result.player_id] ||= PlayerStatistics.new(
            player: result.player,
            games_count: 0,
            captures: 0,
            dragons: 0,
            skulls: 0
          )
          row.games_count += 1
          row.captures += result.ranking_captures
          row.dragons += result.dragons.to_i if @game_format.tracks_dragons?
          row.skulls += result.skulls.to_i if @game_format.tracks_skulls?
        end
      end
    end

    statistics.values.sort_by do |row|
      [
        -row.captures,
        -row.dragons,
        -row.skulls,
        row.player.display_name.to_s.downcase,
        row.player.nickname.to_s.downcase,
        row.player.id
      ]
    end
  end

  def build_nominations(rows)
    AchievementDefinition.for_format(@game_format).map do |definition|
      max_value = rows.map { |row| row.public_send(definition.metric) }.max.to_i
      leaders = max_value.positive? ? rows.select { |row| row.public_send(definition.metric) == max_value } : []

      Nomination.new(
        definition: definition,
        max_value: max_value,
        leaders: leaders
      )
    end
  end

  def completeness_problems(tours)
    return [ "Нет ни одного сыгранного тура." ] if tours.empty?

    problems = []
    tours.each do |tour|
      validate_tour(tour, problems)
    end
    problems.uniq
  end

  def validate_tour(tour, problems)
    games_by_letter = tour.games.index_by(&:table_letter)
    tour.table_letters.each do |table_letter|
      game = games_by_letter[table_letter]
      unless game
        problems << "Тур #{tour.number}, стол #{table_letter}: стол не создан."
        next
      end

      validate_game(tour, game, problems)
    end

    tour.games.each do |game|
      next if tour.table_letters.include?(game.table_letter) || game.game_results.empty?

      problems << "Тур #{tour.number}, стол #{game.table_letter}: стол не входит в текущую настройку тура, но содержит результаты."
      validate_result_fields(tour, game, problems)
    end

    validate_player_table_uniqueness(tour, tour.games, problems)
  end

  def validate_game(tour, game, problems)
    results = game.game_results.to_a
    expected_count = @game_format.players_per_table

    if results.size != expected_count
      problems << "Тур #{tour.number}, стол #{game.table_letter}: ожидается #{expected_count} результатов, найдено #{results.size}."
    end

    validate_result_fields(tour, game, problems)

    actual_places = results.filter_map(&:place).sort
    expected_places = @game_format.place_range.to_a
    return if actual_places == expected_places

    problems << "Тур #{tour.number}, стол #{game.table_letter}: места должны быть уникальными и образовывать диапазон #{expected_places.first}–#{expected_places.last}."
  end

  def validate_result_fields(tour, game, problems)
    game.game_results.each do |result|
      missing_fields = required_missing_fields(result)
      next if missing_fields.empty?

      problems << "Тур #{tour.number}, стол #{game.table_letter}, #{result_label(result)}: не заполнено — #{missing_fields.join(', ')}."
    end
  end

  def required_missing_fields(result)
    fields = []
    fields << "игрок" if result.player_id.blank?
    fields << "дом" if result.house.blank?
    fields << "место" if result.place.nil?
    fields << "очки" if result.points.nil?
    fields << "драконы" if @game_format.tracks_dragons? && result.dragons.nil?
    fields << "черепки" if @game_format.tracks_skulls? && result.skulls.nil?
    fields
  end

  def validate_player_table_uniqueness(tour, games, problems)
    appearances = Hash.new { |hash, player_id| hash[player_id] = [] }

    games.each do |game|
      game.game_results.each do |result|
        appearances[result.player_id] << [ game.table_letter, result.player ] if result.player_id
      end
    end

    appearances.each_value do |entries|
      table_letters = entries.map(&:first).uniq.sort
      next unless table_letters.size > 1

      player = entries.first.last
      problems << "Тур #{tour.number}: игрок #{player.nickname} находится за несколькими столами (#{table_letters.join(', ')})."
    end
  end

  def result_label(result)
    result.player&.nickname.presence || "результат ##{result.id || '?'}"
  end
end
