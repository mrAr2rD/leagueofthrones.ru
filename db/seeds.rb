# Admin user
AdminUser.find_or_create_by!(login: "admin") do |u|
  u.password = ENV.fetch("ADMIN_PASSWORD", "password")
end
puts "Admin user created (login: admin)"

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
   • Один игрок — один дом за турнир
   • За 8 туров игрок сыграет каждым домом по одному разу

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

SitePage.find_or_create_by!(slug: "rules") do |p|
  p.title = "Регламент турнира"
  p.content = rules_content.strip
end
puts "Rules page created"

# 28 players
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
  { first_name: "Александр",   nickname: "@arepchenko" }
]

players = players_data.map do |data|
  Player.find_or_create_by!(nickname: data[:nickname]) do |p|
    p.first_name = data[:first_name]
    p.last_name = data[:last_name]
  end
end
puts "#{players.size} players created"

# 8 tours
tours = (1..8).map do |n|
  Tour.find_or_create_by!(number: n) do |t|
    t.played_on = n <= 3 ? Date.new(2026, 1, n * 7) : nil
    t.played = n <= 3
  end
end
puts "#{tours.size} tours created"

# 4 games per tour (7 players per table for 28 players)
tours.each do |tour|
  Game::TABLE_LETTERS.each do |letter|
    Game.find_or_create_by!(tour: tour, table_letter: letter)
  end
end
puts "#{Game.count} games created"

# Test results for tours 1-3
rng = Random.new(42)
shuffled_players = players.shuffle(random: rng)

(0..2).each do |tour_idx|
  tour = tours[tour_idx]
  tour_players = shuffled_players.rotate(tour_idx * 3)

  tour.games.ordered.each_with_index do |game, table_idx|
    table_players = tour_players[table_idx * 7, 7]
    next unless table_players&.size == 7
    house_keys = GameResult::HOUSE_LABELS.keys.shuffle(random: rng)

    table_players.each_with_index do |player, place_idx|
      place = place_idx + 1
      capitals = rng.rand(0..3)
      dragons = rng.rand(0..2)
      castles = rng.rand(0..4)

      gr = GameResult.find_or_initialize_by(game: game, player: player)
      gr.place = place
      gr.capitals = capitals
      gr.dragons = dragons
      gr.castles = castles
      gr.house = house_keys[place_idx]
      gr.points = GameResult::PLACE_POINTS.fetch(place, 0) + (capitals * 2) + dragons + castles
      gr.save!
    end
  end
end
puts "Game results seeded for tours 1-3"

# Set initial rankings
RankingCalculator.recalculate!
puts "Rankings calculated"
