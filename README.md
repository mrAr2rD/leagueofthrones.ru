# League of Thrones

League of Thrones is a Rails application for running and publishing a tournament:

- city-scoped public leaderboards, tour results, player profiles and rules
- published tournament achievements on leaderboards and player profiles
- global gallery login/page
- admin workflows for cities, players, tours, game results, statistics, achievements and editable pages
- two game formats with format-specific scoring and table sizes

## Stack
- Ruby 3.3.6
- Rails 8.1
- PostgreSQL
- Importmap
- Turbo + Stimulus
- Tailwind CSS
- Minitest

## Main Project Areas
- [`config/routes.rb`](config/routes.rb) defines the public and admin entry points.
- [`app/models`](app/models) contains tournament entities and validation rules.
- [`app/controllers/admin`](app/controllers/admin) contains the admin workflows.
- [`app/views/admin`](app/views/admin) contains admin templates.
- [`app/javascript/controllers`](app/javascript/controllers) contains Stimulus behavior for interactive forms.
- [`app/services/ranking_calculator.rb`](app/services/ranking_calculator.rb) recalculates standings.
- [`app/services/tournament_statistics_calculator.rb`](app/services/tournament_statistics_calculator.rb) aggregates per-city, per-format tournament statistics and achievement nominations.
- [`app/models/game_format.rb`](app/models/game_format.rb) is the scoring and format registry shared with the admin points calculator.
- [`db/seeds.rb`](db/seeds.rb) creates a realistic local dataset.
- [`test`](test) contains the Minitest suite and fixtures.

## Quick Start
### 1. Install dependencies
- Ruby `3.3.6`
- Bundler
- PostgreSQL 16+ recommended

### 2. Start PostgreSQL
If you already have local PostgreSQL running, move to the next step.

If not, a simple disposable local instance:

```bash
docker run --name lot-postgres \
  -e POSTGRES_HOST_AUTH_METHOD=trust \
  -e POSTGRES_USER=$(whoami) \
  -e POSTGRES_DB=postgres \
  -p 5432:5432 \
  -d postgres:16
```

The default development config in [`config/database.yml`](config/database.yml) expects PostgreSQL to accept the current OS user unless you override it with `DATABASE_URL` or `PG*` environment variables.

### 3. Bootstrap the app
```bash
bin/setup --skip-server
```

This will:
- install gems
- prepare the database
- clear old logs and temp files

### 4. Start the app
```bash
bin/dev
```

This starts:
- Rails server
- Tailwind watcher

Then open [http://127.0.0.1:3000](http://127.0.0.1:3000).

In a non-TTY or headless shell the Tailwind watcher may exit and make Foreman stop
the web process. In that environment, build CSS once and run Rails directly:

```bash
bin/rails tailwindcss:build
bin/rails server
```

## Seed Data
The seed script creates:

- the default city (`Moscow`) and its rules page
- a superadmin (`admin`) and a Moscow-scoped regular admin (`city_admin`)
- 32 players linked to Moscow
- 8 Mother of Dragons tours with 4 games per tour (`A` to `D`)
- demo game results for the first three tours
- mixed legacy/split capital bonus cases in tour 1, table A
- admin-focused corner cases in tour 4, tables A and B
- an intentionally incomplete statistics demo: fill the blank skull value in tour 1,
  table A before publishing achievements
- no published achievement awards, so the publication flow can be tested explicitly

Run:

```bash
bin/rails db:seed:replant
```

Admin login page:
- [http://127.0.0.1:3000/admin/login](http://127.0.0.1:3000/admin/login)

Seeded credentials:

- superadmin: `admin` / `password`
- city admin: `city_admin` / `password`

Override the passwords with `ADMIN_PASSWORD` and `CITY_ADMIN_PASSWORD`.

## Test Commands
Run the full test suite:

```bash
bin/rails test
```

Run a single test file:

```bash
bin/rails test test/controllers/admin/games_controller_test.rb
```

Run the local CI-style pipeline:

```bash
bin/ci
```

`bin/ci` runs:
- setup
- RuboCop
- bundler-audit
- importmap audit
- Brakeman
- Rails tests
- seed replant check in test env

## Most Frequent Change Areas
### Admin game result editor
If you change result editing behavior, check these files together:
- [`app/views/admin/games/edit.html.erb`](app/views/admin/games/edit.html.erb)
- [`app/javascript/controllers/points_calculator_controller.js`](app/javascript/controllers/points_calculator_controller.js)
- [`app/javascript/controllers/slot_toggle_controller.js`](app/javascript/controllers/slot_toggle_controller.js)
- [`app/controllers/admin/games_controller.rb`](app/controllers/admin/games_controller.rb)
- [`app/models/game_result.rb`](app/models/game_result.rb)
- [`app/services/ranking_calculator.rb`](app/services/ranking_calculator.rb)

Relevant tests:
- [`test/controllers/admin/games_controller_test.rb`](test/controllers/admin/games_controller_test.rb)
- [`test/models/game_result_test.rb`](test/models/game_result_test.rb)
- [`test/models/player_test.rb`](test/models/player_test.rb)

### Public leaderboard
- [`app/controllers/leaderboard_controller.rb`](app/controllers/leaderboard_controller.rb)
- [`app/views/leaderboard/index.html.erb`](app/views/leaderboard/index.html.erb)
- [`app/services/ranking_calculator.rb`](app/services/ranking_calculator.rb)
- [`test/controllers/leaderboard_controller_test.rb`](test/controllers/leaderboard_controller_test.rb)

### Cities, formats, tours and access control
- [`app/models/city.rb`](app/models/city.rb)
- [`app/models/game_format.rb`](app/models/game_format.rb)
- [`app/models/tour.rb`](app/models/tour.rb)
- [`app/controllers/admin/base_controller.rb`](app/controllers/admin/base_controller.rb)
- [`app/controllers/admin/tours_controller.rb`](app/controllers/admin/tours_controller.rb)
- [`test/controllers/admin/access_control_test.rb`](test/controllers/admin/access_control_test.rb)
- [`test/models/tour_test.rb`](test/models/tour_test.rb)

### Tournament statistics and achievements
- [`app/services/tournament_statistics_calculator.rb`](app/services/tournament_statistics_calculator.rb)
- [`app/models/achievement_definition.rb`](app/models/achievement_definition.rb)
- [`app/models/achievement_award.rb`](app/models/achievement_award.rb)
- [`app/controllers/admin/statistics_controller.rb`](app/controllers/admin/statistics_controller.rb)
- [`app/controllers/admin/achievement_publications_controller.rb`](app/controllers/admin/achievement_publications_controller.rb)
- [`test/services/tournament_statistics_calculator_test.rb`](test/services/tournament_statistics_calculator_test.rb)
- [`test/controllers/admin/statistics_controller_test.rb`](test/controllers/admin/statistics_controller_test.rb)

### Player management
- [`app/controllers/admin/players_controller.rb`](app/controllers/admin/players_controller.rb)
- [`app/views/admin/players`](app/views/admin/players)
- [`app/models/player.rb`](app/models/player.rb)

## Domain Notes
- Public pages are scoped by city. Players appear on a city leaderboard only through
  `PlayerCity`, and players with `participates_in_tournament: false` are excluded
  from rankings.
- A player can appear only once per table, but may play at multiple tables in the
  same tour. Each result counts as a separate game.
- Houses must be unique within a game.
- A player cannot reuse the same house across games before the concluding tour.
  In Mother of Dragons' concluding eighth tour, a house from an earlier tour may
  be reused. The admin editor marks such options as `уже играл` and shows an
  explicit warning after selection. Reusing the same house at another table of
  the eighth tour remains forbidden. Classic retains the strict no-reuse rule.
- `Tour#tables_count` controls tables `A` through `D`; reducing the count removes
  only empty tables. `GameFormat` independently controls players per table.
- Tour schedule badges use `starts_on` and `ends_on`. Equal dates render as one
  date; distinct dates render as a range.
- `GameFormat` is the single source of truth for scoring. Mother of Dragons uses
  8 players per table; Classic uses 6 and hides unsupported dragon/skull fields.
- `capitals` is a legacy field. New records may use `capital_captures` and `capital_controls`; when both are `nil`, scoring falls back to legacy `capitals`, and ranking captures also fall back to legacy `capitals`.
- Capital bonus points are still capped at 3 per game, using `min(effective_capitals, 3)`.
- Public leaderboard tie-break order is: `best6_points`, `wins`, ranking `captures`, `dragons`, `lands`.
- Ranking `captures` use `capital_captures` for split-format rows and ignore `capital_controls`; legacy rows use `capitals` as the captures fallback.
- `skulls` are used by format-specific statistics and achievements but do not affect
  public ranking.
- Rankings and previous ranks are calculated independently per city and recalculated
  after result updates.
- `place` may be empty for draft table assignments.
- Tournament statistics aggregate all results from played tours for one city and
  format; unlike the leaderboard, they do not apply the best-six limit.
- Achievement publication is blocked until configured tables contain the expected
  result count, complete fields and a full unique place range. Tied leaders are all
  published. Public pages show only published awards from the visited city.
- Superadmins can access every city and manage cities/admins. Regular admins are
  limited to assigned cities; player records remain global and links to inaccessible
  cities are preserved during edits.

## Useful URLs
- Root redirect: [http://127.0.0.1:3000/](http://127.0.0.1:3000/)
- Moscow leaderboard: [http://127.0.0.1:3000/moscow](http://127.0.0.1:3000/moscow)
- Tour results: [http://127.0.0.1:3000/moscow?tour=1](http://127.0.0.1:3000/moscow?tour=1)
- Moscow rules: [http://127.0.0.1:3000/moscow/rules](http://127.0.0.1:3000/moscow/rules)
- Gallery login: [http://127.0.0.1:3000/gallery/login](http://127.0.0.1:3000/gallery/login)
- Admin root: [http://127.0.0.1:3000/admin](http://127.0.0.1:3000/admin)
- Admin statistics: [http://127.0.0.1:3000/admin/statistics](http://127.0.0.1:3000/admin/statistics)

## Notes For AI Agents
[`AGENTS.md`](AGENTS.md) is tracked in the repository and is the fastest project
entry point for coding agents working on this checkout. Keep it synchronized when
architecture, domain rules, workflows or done criteria change.
