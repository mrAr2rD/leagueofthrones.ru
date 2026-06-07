# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

League of Thrones — a Rails 8.1 tournament site. The public side is a **per-city** leaderboard (Игра Престолов board game tournaments) with player profiles and editable rules; the admin panel manages cities, players, tours, games, results, and pages.

Stack: Ruby 3.3.6, PostgreSQL, Importmap, Turbo + Stimulus, Tailwind CSS, Propshaft, Minitest.

## Commands

| Task | Command |
|---|---|
| Bootstrap | `bin/setup --skip-server` |
| Start dev server + Tailwind | `bin/dev` |
| Run full test suite | `bin/rails test` |
| Run single test file | `bin/rails test test/path/to/file.rb` |
| Run single test by name | `bin/rails test test/path/to/file.rb -n test_name` |
| Full CI (lint + audits + tests + seeds) | `bin/ci` |
| Re-seed local data | `bin/rails db:seed:replant` |
| Lint Ruby | `bin/rubocop` |
| Security scan | `bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error` |

`bin/dev` runs Rails + `tailwindcss:watch` via Procfile.dev; in headless/non-TTY shells the watcher exits and foreman tears down the web process — start `bin/rails server` alone and run `bin/rails tailwindcss:build` once instead.

## Architecture

### Multi-city scoping (the core organizing principle)
The public site is scoped by **city**, addressed by a URL prefix `/:city` (param `:city_id`, value = city `slug`; helpers `city_leaderboard_path`, `city_rules_path`, `city_player_path`):
- `config/routes.rb`: `root` → `cities#index`, which **redirects to the default city** (`City.ordered.first`). The `scope "/:city_id", as: :city` block (leaderboard, rules, player profiles) must stay **after** admin/gallery/health, since `/:city_id` is a catch-all on the first path segment.
- `app/controllers/concerns/city_scoped.rb` sets `@city` from the slug for `leaderboard`, `players`, and `pages` controllers; an unknown slug redirects to root rather than erroring.
- A header city switcher (`app/views/shared/_city_switcher.html.erb`) appears only when more than one city exists.
- `City has_many tours / site_pages / player_cities`, and `players through player_cities` (a player can belong to several cities). Tours and site pages **belong to a city**; their uniqueness is per-city (`[:city_id, :number]` for tours, `[:city_id, :slug]` for pages). Creating a `City` auto-creates its "rules" page (`after_create`).
- The **gallery is intentionally global** (`/gallery`, all players regardless of city), behind a shared password.

### Game formats (data-driven scoring shared with JS)
`app/models/game_format.rb` is a plain-Ruby registry (`mother_of_dragons` = 8 players/table, `classic` = 6) and the **single source of truth for scoring**. Each format carries place points, table-A bonus places, capital cap, and a `castle_rule` expressed **as data** (`linear_cap` or `band` table). A tour has a `format` column; `Tour#game_format` resolves it. The format drives: `GameResult.calculate_points`, league tier size in rankings, the number of result slots in the admin game editor, and — critically — `GameFormat#to_config_json`, the camelCase contract consumed by `app/javascript/controllers/points_calculator_controller.js` so the live JS calculator mirrors the server logic exactly. Change scoring rules in `game_format.rb`, never duplicate them.

### Rankings
`RankingCalculator.call(city)` rebuilds a city's leaderboard; `RankingCalculator.recalculate!(city)` also persists ranks. It scopes players via `city.players` (participating only) and points to that city's **played** tours. League tiers (gold/silver/bronze/iron) are sized by the city's `default_game_format.league_tier_size`. `previous_rank` lives on `player_cities` (not `players`) so rank deltas never mix across cities. Re-run it after any result change — the admin game save does this.

### Admin (flat, not nested under city)
`/admin` (login `admin` / `password` seeded). Controllers are flat: cities (CRUD, slug-addressed), admins (`admin_users`, CRUD), players (CRUD + `city_ids` checkboxes), tours (CRUD with a `_form` choosing city/format/**tables_count**, `?city=slug` filter), pages (CRUD, **id**-addressed since slug is per-city now), and games (nested under tours). The game result editor (`admin/games_controller.rb`) builds `format.players_per_table` slots, scopes selectable players to the tour's city, and saves via `delete_all + insert_all` preserving hidden round-trip fields.

### Tables per tour
A tour has `tables_count` (1..`Game::TABLE_LETTERS.size`, i.e. 1–4). `Tour#table_letters` is `A..N`; `Tour#sync_tables` creates missing tables and deletes empty extras (tables that already have results are kept). Sync is called explicitly from `Admin::ToursController#create/#update` — **not** an `after_save` callback, because that would auto-create games and break tests/flows that build games manually. Players-per-table (format) and tables-per-tour are independent dimensions.

### Access control (roles)
`AdminUser` has a `superadmin` flag and `admin_user_cities` (→ `cities`). `Admin::BaseController` exposes `superadmin?`, `accessible_cities`, `require_superadmin!`, and `authorize_city!(city)` (all `helper_method` where views need them). **Superadmins** manage everything incl. Cities and Admins. **Regular admins** are restricted to assigned cities: tours/games/pages are authorized via `authorize_city!`; their index scopes are limited to `accessible_cities`. Players are global — a regular admin sees only players in their cities, edits preserve a player's links to cities they don't manage (`resolved_city_ids`), and only superadmins delete players. The admin nav hides Cities/Admins for non-superadmins. Existing admins were backfilled to `superadmin = true` so nobody is locked out.

## Domain Rules

- A player appears at most once per table and once per tour (across tables); houses are unique within a game and a player cannot reuse a house across games.
- Tour `number` is unique within a city and bounded by the format's tour count (`number_within_format`).
- Capital scoring: `capital_captures` + `capital_controls` when at least one split field is present; otherwise legacy `capitals`. Bonus capped at the format's `capital_cap` (3).
- Tie-break order: `best6_points` > `wins` > ranking `captures` > `dragons` > `lands`.
- Ranking `captures` use `capital_captures` for split rows, legacy `capitals` when both split fields are NULL; `capital_controls` never counts for ranking captures. `skulls` are stored but never affect ranking. `place` may be NULL (draft assignments).
- A tour's `format` only affects its own games (suggested points, slots, tie-break, league tier); it does **not** retroactively recompute already-saved `GameResult#points` — the leaderboard sums stored points. Different cities can run different formats (e.g. Moscow 8-player, a new city 6-player).

## Conventions

- Do not edit `db/schema.rb` by hand — generate migrations.
- Tests use **fixtures** (not factories). Records created inline in tests must satisfy multi-city constraints: tours/pages need a `city:`, and players need a `PlayerCity` link to appear on a city's leaderboard (see `test/fixtures/cities.yml`, `player_cities.yml`, `site_pages.yml`).
- When changing admin result behavior, update the view, Stimulus controllers (`points_calculator_controller.js`, `slot_toggle_controller.js`), server-side validations, and tests together.
- DB names: `i_pr_development` / `i_pr_test`; config assumes the current OS user for PostgreSQL unless overridden via `DATABASE_URL` / `PG*`.
- In dev, `ActionDispatch::HostAuthorization` returns 403 for non-allowed hosts — drive smoke requests with `HTTP_HOST=localhost`.

## See Also

- `AGENTS.md` — detailed repo map, highest-value files per change area, seeded review pages, and a disposable Docker PostgreSQL one-liner.
- Deployment uses Kamal (`.kamal/`, `bin/kamal`, `Dockerfile`); background jobs run via `bin/jobs` (Solid Queue).
