# CHILLFILTR®

The Rails app behind [chillfiltr.com](https://chillfiltr.com): a curated music
and literature blog with paid song submissions via Stripe and automated
publishing of *The Weekly Catch*, Krister Axel's Wednesday-night show on KSKQ
(89.5 FM Ashland, 94.1 FM Medford).

The archive runs from 1999 to today: roughly 2,200 posts by 35 authors, sorted
into six topics (music, lifestyle, personal, technology, prose, poetry) plus
`radio` for Weekly Catch episodes, with about 90 tags and location labels.

## What it does

- **Blog:** infinite-scroll index, topic filters, tags, author pages, search,
  and a monthly archive. Posts can embed Vimeo, YouTube, or Mixcloud players.
- **Radio page:** the latest Weekly Catch episode plays in a Mixcloud widget,
  with a paginated list of past episodes (4 per page, 16 max).
- **Song submissions:** artists upload tracks straight to S3 and pay $3 per
  song through Stripe Checkout. See [docs/song_submissions.md](docs/song_submissions.md).
- **Accounts:** email/password sign-in plus Google and Apple via OmniAuth.
- **RSS:** feeds for all posts or a single topic.

## Platform

| | |
|---|---|
| Ruby | 3.4.1 |
| Rails | 8.0 |
| Database | PostgreSQL (separate databases for app, Solid Queue, Solid Cache, Solid Cable) |
| Web server | Puma behind Thruster |
| Front end | Hotwire (Turbo + Stimulus), importmap, Tailwind CSS 4 |
| Background jobs | Solid Queue (runs inside Puma when `SOLID_QUEUE_IN_PUMA=true`) |
| File storage | Active Storage on Amazon S3 |
| Payments | Stripe Checkout + webhooks |
| Email | Brevo SMTP |
| Hosting | Render (Docker), Oregon region |

Design: Instrument Serif + Karla, with the "Open Air" palette defined as
Tailwind theme tokens in `app/assets/tailwind/application.css`.

## Getting started

```bash
git clone git@github.com:kaxel/chillonrails.git
cd chillonrails
bin/setup          # installs gems, creates and migrates the database
bin/dev            # Rails server + Tailwind watcher (http://localhost:3000)
```

You need Ruby 3.4.1 and a local PostgreSQL server. Run `bin/rails db:seed` or
restore a dump if you want content to browse.

## Configuration

Production settings live in the Render dashboard (names are listed in
`render.yaml`):

| Variable | Purpose |
|---|---|
| `DATABASE_URL` | PostgreSQL connection |
| `RAILS_MASTER_KEY` | decrypts `config/credentials.yml.enc` |
| `WEB_CONCURRENCY` | Puma workers |
| `SOLID_QUEUE_IN_PUMA` | set to `true` so jobs run in the web process |
| `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` | song submission checkout |
| `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `AWS_S3_BUCKET` | uploaded audio |

Locally, use `.env` (not committed) and Stripe test keys.

## Tests and checks

```bash
bundle exec rspec        # test suite
bin/rubocop              # style (rails-omakase)
bin/brakeman --no-pager  # security scan
bin/importmap audit      # JavaScript dependency audit
```

GitHub Actions (`.github/workflows/ci.yml`) runs Brakeman, the importmap
audit, and RuboCop on every push and pull request.

## Deployment

Render builds the Dockerfile and runs `bin/rails db:migrate` before each
release. Automatic deploys are **off**, so deploy manually from the Render
dashboard after pushing to `main`.

## Publishing a Weekly Catch episode

Episodes are stored as `radio` posts and imported from
`db/data/weekly_catch_episodes.json`.

1. In the `spinitscrape` repo, add the new setlist, then run
   `./export_weekly_catch_to_chillfiltr.rb`. It rewrites the JSON and adds the
   episode's thumbnail to `public/weekly-catch-fish/`.
2. Run `bin/rails weekly_catch:import` locally and check the radio page.
3. Commit and push both files, deploy, then run
   `bin/rails weekly_catch:import` on Render. The radio page's "Now Playing"
   section switches to the newest episode automatically.

The import is safe to re-run: it creates missing episodes and backfills the
Mixcloud link, image, and tracklist on existing ones.

## Scheduled jobs

`config/recurring.yml` runs `PurgePendingSubmissionsJob` daily at 4am,
removing submissions that were never paid for after 24 hours.
