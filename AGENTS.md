# AGENTS.md

## Project Snapshot
- Rails 8.1 application for the League of Thrones tournament site and admin panel.
- Stack: Ruby 3.3.6, PostgreSQL, Importmap, Turbo, Stimulus, Tailwind CSS, Minitest.
- Public surface: leaderboard, player profile pages, rules page, gallery login/page.
- Admin surface: player management, tour management, game result editing, editable site pages.

## Key Domain Objects
- `Player`: tournament participant, photo, nickname, previous rank.
- `Tour`: tournament round. The app expects 8 tours total.
- `Game`: table inside a tour. `Game::TABLE_LETTERS = A..D`.
- `GameResult`: one player's result at one table. Holds house, place, bonus stats and points. Capital scoring is split between `capital_captures` and `capital_controls`, with legacy fallback to `capitals` when both split fields are `NULL`.
- `SitePage`: editable static content such as tournament rules.
- `RankingCalculator`: recomputes leaderboard and league placement from played tours.

## Repo Map
- `app/controllers`
  Public controllers plus `admin/*` for the admin panel.
- `app/models`
  Core tournament rules and validations live here.
- `app/services/ranking_calculator.rb`
  Rebuilds rankings after result changes.
- `app/views/admin`
  Admin UI templates.
- `app/javascript/controllers`
  Stimulus controllers. The admin game editor behavior is here.
- `config/routes.rb`
  Fastest way to understand public/admin entry points.
- `db/migrate`
  Schema changes only belong here.
- `db/seeds.rb`
  Local bootstrap data, admin credentials, demo players/tours/results.
- `test`
  Minitest suite with fixtures.

## Common Entry Points
- Root page: `/`
- Admin login: `/admin/login`
- Admin home: `/admin`
- Rules page: `/rules`
- Gallery login: `/gallery/login`

## Local Run
1. Ensure PostgreSQL is available locally.
2. Run `bin/setup --skip-server`.
3. Start the app with `bin/dev`.
4. Open `http://127.0.0.1:3000`.

Useful seeded review pages after `bin/rails db:seed:replant`:
- Tour 1, table A: mixed legacy/split capital cases for public ranking checks
- Tour 4, table A: admin editor corner cases for empty/partial split capital input
- Tour 4, table B: draft rows and manual points override cases

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
- Run CI-like checks locally: `bin/ci`
- Re-seed local data: `bin/rails db:seed:replant`
- Show routes: `bin/rails routes`

## Highest-Value Files For Common Changes
### Admin game result editor
- View: `app/views/admin/games/edit.html.erb`
- Points preview Stimulus: `app/javascript/controllers/points_calculator_controller.js`
- Stimulus: `app/javascript/controllers/slot_toggle_controller.js`
- Controller: `app/controllers/admin/games_controller.rb`
- Model rules: `app/models/game_result.rb`
- Ranking side-effect: `app/services/ranking_calculator.rb`
- Main tests:
  - `test/controllers/admin/games_controller_test.rb`
  - `test/models/game_result_test.rb`
  - `test/models/player_test.rb`

### Admin player management
- `app/controllers/admin/players_controller.rb`
- `app/views/admin/players`
- `app/models/player.rb`
- `test/controllers/admin/players_controller_test.rb`

### Public leaderboard and player pages
- `app/controllers/leaderboard_controller.rb`
- `app/views/leaderboard`
- `app/controllers/players_controller.rb`
- `app/views/players/show.html.erb`
- `app/services/ranking_calculator.rb`
- `test/controllers/players_controller_test.rb`

## Important Domain Rules
- A player cannot appear twice at the same table.
- A player cannot appear at two different tables in the same tour.
- Houses must be unique within one game.
- A player cannot reuse the same house across different games.
- In the admin editor, a row is considered valid only if both `player` and `house` are filled, or both are blank.
- `capitals` is legacy-only input. Effective capital scoring uses `capital_captures + capital_controls` when at least one split field is present; otherwise it falls back to legacy `capitals`.
- Capital bonus points are capped at 3, but ranking tie-break does not use `effective_capitals`.
- Ranking tie-break order is `best6_points`, `wins`, ranking `captures`, `dragons`, `lands`.
- Ranking `captures` use legacy `capitals` only when both split capital fields are `NULL`; otherwise they use only `capital_captures` and ignore `capital_controls`.
- Public player profile history should stay consistent with leaderboard wording and ranking data: use `Захваты`/`ranking_captures`, and render the played house via `house_name`.
- `skulls` are stored for future rules but do not affect ranking yet.
- `place` may be `NULL` for draft assignments; points and ranking logic only consider meaningful filled results.
- Ranking is recalculated after saving game results.

## Working Conventions For Agents
- Prefer reading `config/routes.rb` first when exploring behavior.
- Prefer `rg` for search and `bin/rails test path/to/test.rb` for targeted validation.
- Do not edit `db/schema.rb` manually; generate migrations and let Rails update schema.
- When changing admin result behavior, update all of:
  - view
  - points preview Stimulus controller
  - Stimulus controller
  - server-side validations / save flow
  - relevant controller/model tests
- The admin game result save flow recreates rows with `delete_all + insert_all`; preserve hidden round-trip fields when adding compatibility logic for existing records.
- Seeds are used as a realistic local scenario; avoid breaking `bin/rails db:seed:replant`.
- The project uses fixtures, not factories.

## Done Criteria
- Run targeted tests for the changed area.
- If domain rules, migrations, or save flow changed, run full `bin/rails test`.
- If UI behavior changed in admin, verify manually in the browser.
