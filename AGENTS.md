# AGENTS.md

## Project Snapshot
- Rails 8.1 application for the League of Thrones tournament site and admin panel.
- Stack: Ruby 3.3.6, PostgreSQL, Importmap, Turbo, Stimulus, Tailwind CSS, Minitest.
- Public surface is **scoped by city** (URL prefix `/:city`): leaderboard, player profile pages, rules page and a mobile-first Tides of Battle pass-and-play draw. Plus a **global** gallery login/page.
- Admin surface: city/admin management, player management (incl. city membership), tour management (incl. format and dates), game result editing, tournament statistics, achievement publication, editable site pages.

## Key Domain Objects
- `City`: a tournament location, addressed by `slug` (`to_param`). Has many tours, site pages, player_cities and Tides of Battle sessions; has many players through player_cities. Holds `default_format`. Auto-creates its "rules" page on create.
- `PlayerCity`: join between players and cities (city roster). Holds `previous_rank` (per-city, for rank deltas).
- `Player`: tournament participant (photo, nickname). Belongs to many cities through player_cities; appears only on the leaderboards of cities it is linked to and only while `participates_in_tournament` is enabled.
- `Tour`: tournament round. Belongs to a city. Has a `format`, `tables_count` (1–4), `played_on`, `starts_on` and `ends_on`; `number` unique within a city, bounded by the format's tour count. `Tour#sync_tables` reconciles its games (tables) to `tables_count`; `date_range_label` renders equal start/end dates once.
- `Game`: table inside a tour. `Game::TABLE_LETTERS = A..D` (cap on tables_count).
- `AdminUser`: has `superadmin` flag and `cities` (through `admin_user_cities`). Superadmin = full access; regular admin = scoped to assigned cities. `accessible_cities`, `can_access_city?`.
- `GameResult`: one player's result at one table — house, place, bonus stats, points. Capital scoring splits into `capital_captures` + `capital_controls`, with legacy fallback to `capitals` when both split fields are `NULL`.
- `GameFormat` (plain Ruby, not a model): registry of formats (`mother_of_dragons` = 8/table, `classic` = 6/table). **Single source of truth for scoring** — place points, table-A bonus, capital cap, and a data-driven `castle_rule`. `#to_config_json` is the contract consumed by the JS points calculator.
- `SitePage`: editable static content (e.g. rules), belongs to a city; `slug` unique per city.
- `RankingCalculator`: recomputes a **single city's** leaderboard and league placement from that city's played tours.
- `TournamentStatisticsCalculator`: aggregates every result from played tours for one city and format, validates publication completeness, and calculates achievement nominations.
- `AchievementDefinition`: registry of format-aware achievement definitions (`conqueror`, `dragon_slayer`, `faceless_chosen`).
- `AchievementAward`: persisted achievement snapshot scoped by city, game format, achievement and player; only rows with `published_at` are public.
- `TidesOfBattleSession`: tokenized combat session for one shared phone. Owns a shuffled 24-card deck, attacker/defender cards, the single Valyrian Steel Blade reroll and final reveal state. Sessions are scoped by city and isolated between tables.

## Repo Map
- `app/controllers`
  Public controllers (city-scoped via the concern) plus `admin/*`.
- `app/controllers/concerns/city_scoped.rb`
  Sets `@city` from the `/:city` slug for public controllers.
- `app/models`
  Core tournament rules and validations. `game_format.rb` holds all scoring rules.
- `app/services/ranking_calculator.rb`
  Rebuilds a city's rankings after result changes (`call(city)` / `recalculate!(city)`).
- `app/services/tournament_statistics_calculator.rb`
  Builds sortable tournament statistics, completeness problems and achievement nominations for a city/format.
- `app/views/admin`
  Admin UI templates. `app/views/shared/_city_switcher.html.erb` is the public city switcher.
- `app/javascript/controllers`
  Stimulus controllers. The admin game editor behavior is here; `points_calculator_controller.js` mirrors `GameFormat`.
- `config/routes.rb`
  Fastest way to understand public/admin entry points (note the trailing `scope "/:city_id"`).
- `db/migrate`
  Schema changes only belong here.
- `db/seeds.rb`
  Local bootstrap data: default city (Москва), admin credentials, demo players/tours/results.
- `test`
  Minitest suite with fixtures.

## Common Entry Points
- Root: `/` → redirects to the default city's leaderboard (`City.ordered.first`).
- City leaderboard: `/:city` (e.g. `/moscow`); filter a tour with `?tour=N`.
- City rules: `/:city/rules`; player profile: `/:city/players/:id`.
- Tides of Battle: `/:city/tides-of-battle` creates a fresh session and redirects to its tokenized URL.
- Tides of Battle beta: `/:city/tides-of-battle-beta` keeps the same session rules with a result-aware reel animation; the classic tool links to it and remains available separately.
- Gallery (global): `/gallery`, login `/gallery/login`.
- Admin login: `/admin/login`; admin home: `/admin`; tournament statistics: `/admin/statistics`.

## Local Run
1. Ensure PostgreSQL is available locally.
2. Run `bin/setup --skip-server`.
3. Start the app with `bin/dev`.
4. Open `http://127.0.0.1:3000`.

`bin/dev` runs web + Tailwind watcher via Procfile.dev; in a non-TTY/headless shell the watcher exits and foreman stops the web process too — instead run `bin/rails server` alone and `bin/rails tailwindcss:build` once. In development `ActionDispatch::HostAuthorization` returns 403 for non-allowed hosts; drive scripted requests with `HTTP_HOST=localhost`.

Useful seeded review pages after `bin/rails db:seed:replant` (all under the default city `/moscow`):
- Tour 1, table A: mixed legacy/split capital cases for public ranking checks
- Tour 4, table A: admin editor corner cases for empty/partial split capital input
- Tour 4, table B: draft rows and manual points override cases
- Achievement awards are intentionally unpublished; statistics publication is intentionally blocked until the blank skull value in tour 1, table A is filled

Seeded admin credentials:
- login: `admin`
- password: `password`

## Local Database Notes
- Development DB: `i_pr_development`
- Test DB: `i_pr_test`
- `config/database.yml` assumes the default PostgreSQL role matches the current OS user unless `DATABASE_URL` or `PG*` env vars are set.
- If PostgreSQL is not installed locally, a simple disposable option is:
  `docker run --name lot-postgres -e POSTGRES_HOST_AUTH_METHOD=trust -e POSTGRES_USER=$(whoami) -e POSTGRES_DB=postgres -p 5432:5432 -d postgres:16`

## Fast Commands
- Setup without starting the app: `bin/setup --skip-server`
- Start web + Tailwind watcher: `bin/dev`
- Run full test suite: `bin/rails test`
- Run a single test: `bin/rails test test/path/to/file.rb -n test_name`
- Run CI-like checks locally: `bin/ci`
- Re-seed local data: `bin/rails db:seed:replant`
- Show routes: `bin/rails routes`

## Highest-Value Files For Common Changes
### City scoping / routing
- `config/routes.rb` (trailing `scope "/:city_id"` must stay after admin/gallery/health)
- `app/controllers/concerns/city_scoped.rb`
- `app/views/shared/_city_switcher.html.erb`
- `app/controllers/cities_controller.rb` (root → default city)
- Tests: `test/controllers/cities_controller_test.rb`, `leaderboard_controller_test.rb`, `pages_controller_test.rb`

### Scoring / game formats
- `app/models/game_format.rb` (place points, castle_rule, capital cap, `to_config_json`)
- `app/javascript/controllers/points_calculator_controller.js` (must mirror `to_config_json`)
- `app/models/game_result.rb` (`calculate_points`, capital/ranking logic)
- Tests: `test/models/game_format_test.rb`, `test/models/game_result_test.rb`

### Admin game result editor
- View: `app/views/admin/games/edit.html.erb`
- Stimulus: `points_calculator_controller.js`, `slot_toggle_controller.js`
- Controller: `app/controllers/admin/games_controller.rb` (slot count = `format.players_per_table`; players scoped to `@tour.city`)
- Ranking side-effect: `app/services/ranking_calculator.rb`
- Tests: `test/controllers/admin/games_controller_test.rb`, `test/models/game_result_test.rb`

### Admin city / tour / page / player / admin management
- `app/controllers/admin/{cities,tours,pages,players,admin_users}_controller.rb` and `app/views/admin/{cities,tours,pages,players,admin_users}`
- `app/models/{city,tour,site_page,player,player_city,admin_user,admin_user_city}.rb`
- Tests: `test/controllers/admin/{cities,tours,pages,players,admin_users}_controller_test.rb`, `test/models/{city,tour,admin_user}_test.rb`

### Access control (roles) & tables per tour
- `app/controllers/admin/base_controller.rb` — `superadmin?`, `accessible_cities`, `require_superadmin!`, `authorize_city!`. Cities & AdminUsers controllers are superadmin-only; Tours/Games/Pages/Players authorize/scope by city.
- Tables: `Tour#tables_count` + `Tour#sync_tables`, called from `Admin::ToursController#create/#update`; selector in `app/views/admin/tours/_form.html.erb`.
- Tests: `test/controllers/admin/access_control_test.rb`, `test/controllers/admin/admin_users_controller_test.rb`

### Public leaderboard and player pages
- `app/controllers/{leaderboard,players}_controller.rb`, `app/views/{leaderboard,players}`
- `app/services/ranking_calculator.rb`
- Tests: `test/controllers/{leaderboard,players}_controller_test.rb`, `test/services/ranking_calculator_test.rb`

### Tournament statistics & achievements
- Registry/models: `app/models/{achievement_definition,achievement_award}.rb`
- Calculator: `app/services/tournament_statistics_calculator.rb`
- Admin read/sort UI: `app/controllers/admin/statistics_controller.rb`, `app/views/admin/statistics/show.html.erb`
- Publish/refresh/unpublish flow: `app/controllers/admin/achievement_publications_controller.rb`
- Public badges/cards: `app/controllers/{leaderboard,players}_controller.rb`, `app/views/{leaderboard,players}`
- Tests: `test/services/tournament_statistics_calculator_test.rb`, `test/controllers/admin/statistics_controller_test.rb`, `test/models/achievement_award_test.rb`

### Tides of Battle pass-and-play draw
- Model/deck rules: `app/models/tides_of_battle_session.rb`
- Controller/session flow: `app/controllers/tides_of_battle_sessions_controller.rb`, `app/controllers/tides_of_battle_beta_sessions_controller.rb`
- Mobile-first UI: `app/views/tides_of_battle_sessions`, `app/views/tides_of_battle_beta_sessions`, `app/assets/stylesheets/application.css`
- Main-page entry point: `app/views/leaderboard/index.html.erb`
- Tests: `test/models/tides_of_battle_session_test.rb`, `test/controllers/tides_of_battle_sessions_controller_test.rb`, `test/controllers/tides_of_battle_beta_sessions_controller_test.rb`

## Important Domain Rules
- A player cannot appear twice at the same table, but may play at multiple tables in the same tour. Each result counts as a separate game in rankings and tournament statistics.
- Houses are unique within one game. A player cannot reuse the same house across games except in Mother of Dragons' concluding eighth tour, where a house from tours 1–7 may be reused. The same player still cannot reuse one house at another table of tour 8, and Classic keeps the strict no-reuse rule. The admin editor marks previously played houses and warns explicitly when one is selected. Houses available per format come from `GameFormat#house_options`.
- A player appears on a city's leaderboard only if linked via `player_cities` and `participates_in_tournament` is not false. Tour `number` is unique per city; `SitePage` `slug` is unique per city.
- In the admin editor, a row is valid only if both `player` and `house` are filled, or both are blank. The editor renders `format.players_per_table` slots.
- `capitals` is legacy-only input. Effective capital scoring uses `capital_captures + capital_controls` when at least one split field is present; otherwise legacy `capitals`. Capital bonus is capped at the format's `capital_cap` (3); ranking tie-break does not use `effective_capitals`.
- Ranking tie-break order: `best6_points`, `wins`, ranking `captures`, `dragons`, `lands`.
- Ranking `captures` use legacy `capitals` only when both split fields are `NULL`; otherwise only `capital_captures` (never `capital_controls`).
- League tiers (gold/silver/bronze/iron) are sized by the city's `default_game_format.league_tier_size`. `previous_rank` is stored per-city on `player_cities`, so rank deltas never mix across cities.
- Keep public player profile wording/data consistent with the leaderboard; show `ranking_captures` in the captures column and castles in the rightmost castle-icon column; results are scoped to the visited city's tours.
- `skulls` feed format-specific statistics/achievements but do not affect ranking. `place` may be `NULL` for draft assignments.
- Ranking is recalculated (for the tour's city) after saving game results.
- A tour's `tables_count` (1–4) controls how many tables (games A–D) it has; reducing it only removes empty tables. Players-per-table comes from the format, independent of tables_count.
- Tour schedule labels use `starts_on`/`ends_on`: one present date is shown alone, equal dates are shown once, and different dates are shown as a range. `ends_on` cannot precede `starts_on`.
- Changing a tour's `format` does NOT recompute already-saved `points`; the leaderboard sums stored points. Cities can run different formats (e.g. 8-player Moscow, 6-player new city).
- Tournament statistics are scoped by city and game format and aggregate all results from played tours (no best-six limit). Sorting is available only for metrics tracked by that format.
- Achievement publication requires complete configured tables: expected player count, required fields and a unique full place range. Unexpected result-bearing tables are reported as problems; tied nomination leaders are all published.
- Public leaderboard/profile pages show only published achievements from the visited city. Refreshing publication replaces the current published snapshot; unpublishing keeps historical award rows but clears `published_at`.
- Regular admins act only within their assigned cities. Players are global: a regular admin sees players in their cities, edits keep a player's links to other cities, and only superadmins delete players.
- Every Tides of Battle combat uses a freshly shuffled official 24-card deck: 8× `+0`, 2× `+0 skull`, 4× `+1 sword`, 4× `+1 fortification`, 4× `+2`, 2× `+3`.
- Attacker and defender draw without replacement from one session deck. A reroll is blocked until both have drawn, is available only once per combat, and draws from the remaining deck without returning either player's initial card. An identical face may still appear when another physical copy remains.
- Hidden Tides of Battle cards must not be embedded in the other side's rendered markup. A private peek renders only the selected side, and battle responses disable browser/Turbo caching so a hidden card is not restored from navigation history.

## Working Conventions For Agents
- Read `config/routes.rb` first when exploring behavior.
- Prefer `rg` for search and `bin/rails test path/to/test.rb` for targeted validation.
- Do not edit `db/schema.rb` manually; generate migrations.
- Change scoring rules only in `app/models/game_format.rb`, then mirror in `points_calculator_controller.js` — never duplicate the math elsewhere.
- Change achievement names, applicability, metrics and icons in `app/models/achievement_definition.rb`; keep statistics, publication and public rendering tests aligned.
- When changing statistics completeness or aggregation, cover both `TournamentStatisticsCalculator` and the admin publication controller. Preserve the distinction between leaderboard best-six scoring and all-game statistics.
- When changing admin result behavior, update all of: view, both Stimulus controllers, server-side validations / save flow, and relevant controller/model tests. The save flow recreates rows with `delete_all + insert_all`; preserve hidden round-trip fields.
- The project uses fixtures, not factories. Records created inline in tests must satisfy multi-city constraints: tours/pages need a `city:`; players need a `PlayerCity` link to appear on a city's leaderboard (`test/fixtures/cities.yml`, `player_cities.yml`, `site_pages.yml`). Admin fixtures: `admin` is `superadmin: true`, `city_admin` is a regular admin scoped to Moscow via `admin_user_cities.yml`.
- Seeds are a realistic local scenario; avoid breaking `bin/rails db:seed:replant`.
- When changing Tides of Battle behavior, preserve row locking for concurrent draws, the shared-deck/no-replacement rule, the global one-reroll limit and side-specific private rendering. Cover both model transitions and controller visibility.

## Done Criteria
- Run targeted tests for the changed area.
- If domain rules, migrations, or save flow changed, run full `bin/rails test`.
- If UI behavior changed in admin or public, verify manually in the browser.
