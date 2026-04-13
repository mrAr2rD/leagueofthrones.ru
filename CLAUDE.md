# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

League of Thrones — a Rails 8.1 tournament site with a public leaderboard and an admin panel for managing players, tours, games, and results.

Stack: Ruby 3.3.6, PostgreSQL, Importmap, Turbo + Stimulus, Tailwind CSS, Propshaft, Minitest.

## Commands

| Task | Command |
|---|---|
| Bootstrap | `bin/setup --skip-server` |
| Start dev server + Tailwind | `bin/dev` |
| Run full test suite | `bin/rails test` |
| Run single test file | `bin/rails test test/path/to/file.rb` |
| Run single test by name | `bin/rails test test/path/to/file.rb -n test_name` |
| CI pipeline (lint + audit + tests + seeds) | `bin/ci` |
| Re-seed local data | `bin/rails db:seed:replant` |
| Lint Ruby | `bin/rubocop` |
| Security scan | `bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error` |

## Architecture

Routes (`config/routes.rb`) define two surfaces:
- **Public**: leaderboard (`/`), player profiles (`/players/:id`), rules (`/rules`), gallery (`/gallery`).
- **Admin** (`/admin`): CRUD for players, tours, games (nested under tours), and editable site pages.

Key models: `Player`, `Tour`, `Game` (a table within a tour, letters A-D), `GameResult` (one player's row at one table), `SitePage` (editable content).

`RankingCalculator` (`app/services/ranking_calculator.rb`) rebuilds the leaderboard after any result change.

Stimulus controllers in `app/javascript/controllers/` drive admin game editor interactivity (`points_calculator_controller.js`, `slot_toggle_controller.js`).

## Domain Rules

- A player appears at most once per table and once per tour (across tables).
- Houses are unique within a game; a player cannot reuse the same house across games.
- Capital scoring: `capital_captures` + `capital_controls` when at least one split field is present; otherwise falls back to legacy `capitals`. Bonus capped at 3.
- Tie-break order: `best6_points` > `wins` > ranking `captures` > `dragons` > `lands`.
- Ranking `captures` use `capital_captures` for split rows, legacy `capitals` when both split fields are NULL. `capital_controls` is never used for ranking captures.
- `skulls` are stored but do not affect ranking.
- `place` may be NULL for draft assignments.

## Conventions

- Do not edit `db/schema.rb` manually — generate migrations.
- The admin game result save flow uses `delete_all + insert_all`; preserve hidden round-trip fields when modifying.
- The project uses fixtures (not factories) for tests.
- When changing admin result behavior, update view, Stimulus controllers, server-side validations, and tests together.
- Seeded admin credentials: login `admin`, password `password`.
- DB names: `i_pr_development` / `i_pr_test`. Config assumes the current OS user for PostgreSQL unless overridden with `DATABASE_URL` or `PG*` env vars.
