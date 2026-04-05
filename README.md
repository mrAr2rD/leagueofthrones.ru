# League of Thrones

League of Thrones is a Rails application for running and publishing a tournament:
- public leaderboard and player pages
- rules page
- gallery login/page
- admin panel for players, tours and game results

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

## Seed Data
The seed script creates:
- admin user
- tournament rules page
- 32 players
- 8 tours
- 4 games per tour (`A` to `D`)
- demo game results for the first tours
- mixed legacy/split capital bonus cases in tour 1, table A
- admin-focused corner cases in tour 4, tables A and B

Run:

```bash
bin/rails db:seed:replant
```

Admin login page:
- [http://127.0.0.1:3000/admin/login](http://127.0.0.1:3000/admin/login)

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
- [`app/services/ranking_calculator.rb`](app/services/ranking_calculator.rb)
- [`test/controllers/leaderboard_controller_test.rb`](test/controllers/leaderboard_controller_test.rb)

### Player management
- [`app/controllers/admin/players_controller.rb`](app/controllers/admin/players_controller.rb)
- [`app/views/admin/players`](app/views/admin/players)
- [`app/models/player.rb`](app/models/player.rb)

## Domain Notes
- A player can appear only once per table.
- A player can appear only once per tour, even across different tables.
- Houses must be unique within a game.
- A player cannot reuse the same house across games.
- `capitals` is a legacy field. New records may use `capital_captures` and `capital_controls`; when both are `nil`, scoring falls back to legacy `capitals`, and ranking captures also fall back to legacy `capitals`.
- Capital bonus points are still capped at 3 per game, using `min(effective_capitals, 3)`.
- Public leaderboard tie-break order is: `best6_points`, `wins`, ranking `captures`, `dragons`, `lands`.
- Ranking `captures` use `capital_captures` for split-format rows and ignore `capital_controls`; legacy rows use `capitals` as the captures fallback.
- `skulls` are stored in `GameResult` for future tournament rules but do not affect public ranking.
- Rankings are recalculated after result updates.
- `place` may be empty for draft table assignments.

## Useful URLs
- Public leaderboard: [http://127.0.0.1:3000/](http://127.0.0.1:3000/)
- Rules page: [http://127.0.0.1:3000/rules](http://127.0.0.1:3000/rules)
- Gallery login: [http://127.0.0.1:3000/gallery/login](http://127.0.0.1:3000/gallery/login)
- Admin root: [http://127.0.0.1:3000/admin](http://127.0.0.1:3000/admin)

## Notes For AI Agents
You can keep a local-only `AGENTS.md` in the repo root as the fastest project entry point for coding agents working on this checkout.
