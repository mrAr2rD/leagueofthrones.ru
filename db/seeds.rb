# Admin users
admin = AdminUser.find_or_initialize_by(login: "admin")
admin.password = ENV.fetch("ADMIN_PASSWORD", "password")
admin.superadmin = true
admin.save!
puts "Admin user created (login: admin)"

# Город по умолчанию — все туры, страницы и игроки привязаны к нему.
moscow = City.find_or_create_by!(slug: "moscow") do |c|
  c.name = "Москва"
  c.register_url = "https://t.me/aesmic"
  c.default_format = GameFormat::DEFAULT_KEY
  c.position = 0
end
puts "City created (#{moscow.name})"

city_admin = AdminUser.find_or_initialize_by(login: "city_admin")
city_admin.password = ENV.fetch("CITY_ADMIN_PASSWORD", "password")
city_admin.superadmin = false
city_admin.save!
AdminUserCity.find_or_create_by!(admin_user: city_admin, city: moscow)
puts "City admin created (login: city_admin, city: #{moscow.name})"

def assign_houses_for_players(players, used_houses_by_player, rng)
  player_options = players.map do |player|
    available_houses = GameResult::HOUSE_LABELS.keys - used_houses_by_player.fetch(player.id, [])
    raise "Для #{player.nickname} не осталось свободных домов" if available_houses.empty?

    [ player, available_houses.shuffle(random: rng) ]
  end.sort_by { |(_player, available_houses)| available_houses.length }

  assignment = resolve_house_assignment(player_options, [])
  raise "Не удалось подобрать уникальные дома для стола" unless assignment

  assignment.to_h
end

def resolve_house_assignment(player_options, taken_houses)
  return [] if player_options.empty?

  player, available_houses = player_options.first

  available_houses.each do |house|
    next if taken_houses.include?(house)

    assignment = resolve_house_assignment(player_options.drop(1), taken_houses + [ house ])
    return [ [ player.id, house ], *assignment ] if assignment
  end

  nil
end

def suggested_points_for_seed(game:, place:, capitals:, capital_captures:, capital_controls:, dragons:, castles:)
  GameResult.calculate_points(
    place: place,
    capitals: capitals,
    capital_captures: capital_captures,
    capital_controls: capital_controls,
    dragons: dragons,
    castles: castles,
    table_letter: game.table_letter
  )
end

def apply_case_attributes!(result, attrs)
  result.place = attrs[:place]
  result.capitals = attrs.fetch(:capitals, 0)
  result.capital_captures = attrs[:capital_captures]
  result.capital_controls = attrs[:capital_controls]
  result.lands = attrs[:lands]
  result.skulls = attrs[:skulls]
  result.dragons = attrs.fetch(:dragons, 0)
  result.castles = attrs.fetch(:castles, 0)

  suggested_points = suggested_points_for_seed(
    game: result.game,
    place: result.place,
    capitals: result.capitals,
    capital_captures: result.capital_captures,
    capital_controls: result.capital_controls,
    dragons: result.dragons,
    castles: result.castles
  )

  result.points = if attrs.key?(:points)
    attrs[:points]
  elsif attrs.key?(:manual_offset)
    suggested_points.nil? ? nil : suggested_points + attrs[:manual_offset]
  else
    suggested_points
  end

  result.save!
end

def overwrite_existing_results_with_cases!(game:, cases:)
  results = game.game_results.order(:place).to_a
  raise "Недостаточно результатов в #{game.tour.number}#{game.table_letter} для кейсов" if results.size < cases.size

  results.zip(cases).each do |result, attrs|
    apply_case_attributes!(result, attrs)
    puts "Public case T#{game.tour.number}#{game.table_letter}: #{result.player.nickname} — #{attrs.fetch(:label)}"
  end
end

def seed_case_game!(game:, players:, cases:, used_houses_by_player:, rng:)
  raise "Число игроков и кейсов должно совпадать" unless players.size == cases.size

  game.game_results.delete_all
  house_assignment = assign_houses_for_players(players, used_houses_by_player, rng)

  players.zip(cases).each do |player, attrs|
    result = GameResult.new(
      game: game,
      player: player,
      house: house_assignment.fetch(player.id)
    )
    apply_case_attributes!(result, attrs)
    used_houses_by_player[player.id] |= [ result.house ]
    puts "Admin case T#{game.tour.number}#{game.table_letter}: #{player.nickname} — #{attrs.fetch(:label)}"
  end
end

# Rules page
rules_content = <<~RULES
  🏆 РЕГЛАМЕНТ ТУРНИРА v1.25

  A Game of Thrones (2nd Edition) + Mother of Dragons

  ⸻

  **Формат:**
   • 16 игроков, 8 туров
   • В туре 2 стола по 8 игроков: Стол A (высшая лига) и Стол B (вторая лига) — первичное распределение происходит по количеству сыгранных игр (сверху опытные игроки, снизу — менее опытные)
   • Все партии доигрываются: победа или конец 10-го хода

  ⸻

  **Дома:**
   • В партии участвуют все 8 домов, без повторов
   • В турах 1–7 игрок не может повторно выбрать уже сыгранный дом
   • В заключительном 8-м туре можно повторить дом из прошлых туров; админка явно помечает такой выбор
   • На разных столах 8-го тура один игрок не может повторить один и тот же дом

  ⸻

  **Столы и ротация**
   После каждого тура:
   • 3 худших со Стола A → Стол B
   • 3 лучших со Стола B → Стол A
   • Ротация определяется по местам, не по очкам
   Пропуск игры: со Стола A → Стол B

  ⸻

  **Очки за место**

  1 — 12
  2 — 7
  3 — 6
  4 — 5
  5 — 4
  6 — 3
  7 — 2
  8 — 1

  Бонус Стола A: 1–3 места получают +1 очко

  ⸻

  **Дополнительные очки:**

  **Замки / Лояльность**

   • +1 очко за каждый замок/крепость в конце партии
   • Таргариен: +1 очко за жетон лояльности (жетон = замок)

  Максимум: 5 очков за партию

  ⸻

  **Столицы**

  Единый максимум: 3 очка за партию за все действия ниже суммарно

  Захват столицы:
   • +1 очко за первый захват чужой столицы с гарнизоном
   • Повторные захваты не считаются
   • Захват только драконами — не считается
   • Захват с наземными юнитами — считается
   • Королевская Гавань не дает бонуса за захват

  Контроль столицы в конце партии:
   • +1 очко за контроль любой столицы (включая Королевскую Гавань)

  ⸻

  **Убийство драконов**

  +1 очко за каждого убитого дракона
  +1 очко за каждого убитого дракона игроку, который оказал поддержку в сражении в том случае, если совокупная сила этой поддержки составила 25% и более от общей силы сражающихся (без учета карт и их модификаторов)

  ⸻

  **ИТОГОВЫЙ ЗАЧЕТ**

  В зачёт идут только 6 лучших партий из 8

  2 худших результата/пропуска игры у каждого игрока — отбрасываются

  ⸻

  **Дополнительные призы турнира:**

  🏰 Завоеватель — больше всего захваченных чужих столиц с гарнизоном за турнир

  🐉 Драконоборец — больше всего убитых драконов за турнир

  🎲 Секретный ачивмент — узнаем в конце турнира
RULES

# Страница «Правила» автосоздаётся при создании города; здесь задаём полный текст.
rules_page = SitePage.find_or_initialize_by(slug: "rules", city: moscow)
rules_page.update!(title: "Регламент турнира", content: rules_content.strip)
puts "Rules page created"

# 32 players
players_data = [
  { first_name: "Семён",      nickname: "@samzakharov" },
  { first_name: "Артем",       nickname: "@aesmic" },
  { first_name: "Иван",        nickname: "@IoIein" },
  { first_name: "Артур",       nickname: "@Avdemkin" },
  { first_name: "Алексей",     nickname: "@Word_Eater" },
  { first_name: "Тимофей",     nickname: "@Timmy_Growler" },
  { first_name: "Александр",   nickname: "@al_chernyshev" },
  { first_name: "Владимир",    nickname: "@I_am_testuser" },
  { first_name: "Луиз",        nickname: "@ljonata" },
  { first_name: "Тимур",       nickname: "@TimKul" },
  { first_name: "Мария",       nickname: "@boyarshinoova" },
  { first_name: "Владимир",    nickname: "@operatormontazher" },
  { first_name: "Екатерина",   nickname: "@Katerosis" },
  { first_name: "Александр",   nickname: "@mrs4ndr" },
  { first_name: "Самвел",      nickname: "@livmass" },
  { first_name: "Эмиль",       nickname: "@rxll3r" },
  { first_name: "Артем",       nickname: "@Strshlyuk" },
  { first_name: "Всеволод",    nickname: "@Bersaler" },
  { first_name: "Анатолий",    nickname: "@Sukharev_A" },
  { first_name: "Владислав",   nickname: "@Grand_Moff_Vlad" },
  { first_name: "Иван",        nickname: "Furry" },
  { first_name: "Юрий",        nickname: "@nastolkovich" },
  { first_name: "Олег",        nickname: "@The_Great_One316" },
  { first_name: "Виктор",      nickname: "@GRSONE" },
  { first_name: "Александар",  nickname: "@Aleksandar_Simic" },
  { first_name: "Стефан",      nickname: "@stefan1378" },
  { first_name: "Савелий",     nickname: "@ChingizCat" },
  { first_name: "Александр",   nickname: "@arepchenko" },
  { first_name: "Дмитрий",     nickname: "@dmtrv" },
  { first_name: "Павел",       nickname: "@pvlv" },
  { first_name: "Никита",      nickname: "@nktv" },
  { first_name: "Кирилл",      nickname: "@krlv" }
]

players = players_data.map do |data|
  Player.find_or_create_by!(nickname: data[:nickname]) do |p|
    p.first_name = data[:first_name]
    p.last_name = data[:last_name]
  end
end
puts "#{players.size} players created"

# Привязываем всех игроков к городу по умолчанию.
players.each { |player| PlayerCity.find_or_create_by!(player: player, city: moscow) }
puts "#{moscow.players.count} players linked to #{moscow.name}"

# 8 tours
tours = (1..8).map do |n|
  Tour.find_or_create_by!(number: n, city: moscow) do |t|
    t.played_on = n <= 3 ? Date.new(2026, 1, n * 7) : nil
    t.played = n <= 3
    base_date = Date.new(2026, 1, 1) + (n - 1) * 14
    t.starts_on = base_date
    t.ends_on = base_date + 1
  end
end
puts "#{tours.size} tours created"

# 4 games per tour (8 players per table for 32 players)
tours.each do |tour|
  Game::TABLE_LETTERS.each do |letter|
    Game.find_or_create_by!(tour: tour, table_letter: letter)
  end
end
puts "#{Game.count} games created"

# Test results for tours 1-3
rng = Random.new(42)
shuffled_players = players.shuffle(random: rng)
used_houses_by_player = Hash.new { |hash, key| hash[key] = [] }

(0..2).each do |tour_idx|
  tour = tours[tour_idx]
  tour_players = shuffled_players.rotate(tour_idx * 3)

  tour.games.ordered.each_with_index do |game, table_idx|
    table_players = tour_players[table_idx * 8, 8]
    next unless table_players&.size == 8
    house_assignment = assign_houses_for_players(table_players, used_houses_by_player, rng)

    table_players.each_with_index do |player, place_idx|
      place = place_idx + 1
      capital_captures = rng.rand(0..2)
      capital_controls = rng.rand(0..2)
      lands = rng.rand(0..15)
      skulls = rng.rand(0..4)
      dragons = rng.rand(0..2)
      castles = rng.rand(0..7)

      gr = GameResult.find_or_initialize_by(game: game, player: player)
      gr.place = place
      gr.capital_captures = capital_captures
      gr.capital_controls = capital_controls
      gr.lands = lands
      gr.skulls = skulls
      gr.dragons = dragons
      gr.castles = castles
      gr.house = house_assignment.fetch(player.id)
      gr.points = GameResult.calculate_points(
        place: place,
        capitals: gr.capitals,
        capital_captures: capital_captures,
        capital_controls: capital_controls,
        dragons: dragons,
        castles: castles,
        table_letter: game.table_letter
      )
      gr.save!
      used_houses_by_player[player.id] |= [ gr.house ]
    end
  end
end
puts "Game results seeded for tours 1-3"

public_corner_case_game = tours[0].games.find_by!(table_letter: "A")
public_corner_cases = [
  { label: "legacy_only_zero", place: 1, capitals: 0, capital_captures: nil, capital_controls: nil, lands: nil, skulls: nil, dragons: 0, castles: 0 },
  { label: "legacy_only_positive", place: 2, capitals: 2, capital_captures: nil, capital_controls: nil, lands: 6, skulls: 1, dragons: 0, castles: 1 },
  { label: "legacy_only_above_cap", place: 3, capitals: 5, capital_captures: nil, capital_controls: nil, lands: 8, skulls: 2, dragons: 1, castles: 2 },
  { label: "split_controls_only_overrides_legacy", place: 4, capitals: 3, capital_captures: nil, capital_controls: 1, lands: 9, skulls: 0, dragons: 0, castles: 3 },
  { label: "split_captures_only_overrides_legacy", place: 5, capitals: 4, capital_captures: 2, capital_controls: nil, lands: 10, skulls: 1, dragons: 2, castles: 0 },
  { label: "split_zeroes_override_legacy", place: 6, capitals: 3, capital_captures: 0, capital_controls: 0, lands: 11, skulls: 2, dragons: 0, castles: 4 },
  { label: "split_sum_under_cap", place: 7, capitals: 1, capital_captures: 1, capital_controls: 1, lands: 12, skulls: 3, dragons: 1, castles: 5 },
  { label: "split_sum_over_cap", place: 8, capitals: 0, capital_captures: 3, capital_controls: 2, lands: 13, skulls: 4, dragons: 0, castles: 6 }
]
overwrite_existing_results_with_cases!(game: public_corner_case_game, cases: public_corner_cases)
puts "Public mixed-format corner cases seeded in tour 1 table A"

admin_corner_case_game_a = tours[3].games.find_by!(table_letter: "A")
admin_corner_case_players_a = players[16, 8]
admin_corner_cases_a = [
  { label: "blank_new_fields_plus_legacy_zero", place: 1, capitals: 0, capital_captures: nil, capital_controls: nil, lands: nil, skulls: nil, dragons: 0, castles: 0 },
  { label: "blank_new_fields_plus_legacy_two", place: 2, capitals: 2, capital_captures: nil, capital_controls: nil, lands: nil, skulls: nil, dragons: 0, castles: 1 },
  { label: "blank_new_fields_plus_legacy_five", place: 3, capitals: 5, capital_captures: nil, capital_controls: nil, lands: nil, skulls: nil, dragons: 1, castles: 2 },
  { label: "blank_captures_filled_controls_legacy_four", place: 4, capitals: 4, capital_captures: nil, capital_controls: 2, lands: 7, skulls: 1, dragons: 0, castles: 2 },
  { label: "filled_captures_blank_controls_legacy_four", place: 5, capitals: 4, capital_captures: 2, capital_controls: nil, lands: 8, skulls: 2, dragons: 1, castles: 1 },
  { label: "explicit_zeroes_override_legacy_three", place: 6, capitals: 3, capital_captures: 0, capital_controls: 0, lands: 0, skulls: 0, dragons: 0, castles: 0 },
  { label: "explicit_zero_capture_blank_control", place: 7, capitals: 3, capital_captures: 0, capital_controls: nil, lands: 1, skulls: 0, dragons: 0, castles: 0 },
  { label: "blank_capture_explicit_zero_control", place: 8, capitals: 3, capital_captures: nil, capital_controls: 0, lands: 2, skulls: 0, dragons: 0, castles: 0 }
]
seed_case_game!(
  game: admin_corner_case_game_a,
  players: admin_corner_case_players_a,
  cases: admin_corner_cases_a,
  used_houses_by_player: used_houses_by_player,
  rng: rng
)
puts "Admin corner cases seeded in tour 4 table A"

admin_corner_case_game_b = tours[3].games.find_by!(table_letter: "B")
admin_corner_case_players_b = players[24, 8]
admin_corner_cases_b = [
  { label: "draft_legacy_only", place: nil, points: nil, capitals: 2, capital_captures: nil, capital_controls: nil, lands: nil, skulls: nil, dragons: 0, castles: 0 },
  { label: "draft_split_controls_only", place: nil, points: nil, capitals: 4, capital_captures: nil, capital_controls: 2, lands: 4, skulls: 0, dragons: 0, castles: 0 },
  { label: "draft_split_captures_only", place: nil, points: nil, capitals: 4, capital_captures: 2, capital_controls: nil, lands: 5, skulls: 1, dragons: 0, castles: 0 },
  { label: "manual_override_split_over_cap", place: 1, capitals: 1, capital_captures: 3, capital_controls: 2, lands: 6, skulls: 2, dragons: 1, castles: 1, manual_offset: 4 },
  { label: "manual_override_legacy_only", place: 2, capitals: 5, capital_captures: nil, capital_controls: nil, lands: 7, skulls: 2, dragons: 0, castles: 2, manual_offset: -2 },
  { label: "all_zero_explicit_new_fields", place: 3, capitals: 2, capital_captures: 0, capital_controls: 0, lands: 0, skulls: 0, dragons: 0, castles: 0 },
  { label: "lands_and_skulls_without_capital_points", place: 4, capitals: 0, capital_captures: nil, capital_controls: nil, lands: 15, skulls: 4, dragons: 0, castles: 0 },
  { label: "mixed_stats_under_cap", place: 5, capitals: 2, capital_captures: 1, capital_controls: 1, lands: 9, skulls: 2, dragons: 2, castles: 3 }
]
seed_case_game!(
  game: admin_corner_case_game_b,
  players: admin_corner_case_players_b,
  cases: admin_corner_cases_b,
  used_houses_by_player: used_houses_by_player,
  rng: rng
)
puts "Admin corner cases seeded in tour 4 table B"

# Set initial rankings
RankingCalculator.recalculate!(moscow)
puts "Rankings calculated"
puts "Achievement awards were not published by seeds"
puts "Statistics demo is intentionally incomplete: fill the blank skull value in tour 1, table A before publishing"
