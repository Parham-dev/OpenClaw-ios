# OpenClaw

A native iOS control room for the OpenClaw AI gateway. Monitor system health, manage cron jobs, track outreach metrics, and oversee your blog pipeline — all from your phone.

Built with SwiftUI and Swift Concurrency. Zero third-party dependencies.

## Screens

| Tab | Description |
|-----|-------------|
| **Home** | Dashboard with 4 summary cards: System Health (ring gauges), Cron Jobs (last/next run), Outreach Stats (grid), Blog Pipeline (published count + stages). Settings via toolbar gear. |
| **Crons** | Full job list with status badges, human-readable schedules, last/next run times, manual run button. Tap → detail view with run history, enable/disable toggle, and manual trigger. |
| **Pipelines** | Coming soon — live per-pipeline cards (Blog, Outreach, WhatsApp, Site Agent) |
| **Memory** | Coming soon — browse and edit workspace files (MEMORY.md, daily notes, skills) |
| **Chat** | Coming soon — streaming conversations with your AI agent via SSE |

### Cron Detail View

Each cron job has a dedicated detail screen:
- **Header** — status badge, enable/disable toggle, "Run Now" button
- **Schedule** — human-readable frequency, raw cron expression, timezone
- **Timing** — last run with status, next run with absolute date, error details
- **Run History** — paginated list (20 per page, load more). Each entry shows status, relative/absolute time, duration, model badge. Tap to expand: token usage (in/out/total) and full markdown summary.

## Getting Started

1. Open `OpenClaw.xcodeproj` in Xcode
2. Build and run on a simulator or device (iOS 17+)
3. On first launch, paste your gateway Bearer token
4. The Home dashboard loads automatically — pull down to refresh

## API

All requests go to `https://api.appwebdev.co.uk` with `Authorization: Bearer <token>`.

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/stats/system` | CPU, RAM, disk, uptime, load |
| GET | `/stats/outreach` | Leads, emails, WhatsApp, conversions |
| GET | `/stats/blog` | Published count, pipeline stages |
| POST | `/tools/invoke` | Tool calls — cron list/runs/run/update, exec |

### Cron Tool Actions

| Action | Args | Purpose |
|--------|------|---------|
| `list` | — | List all cron jobs |
| `runs` | `jobId`, `limit`, `offset` | Paginated run history |
| `run` | `jobId` | Manual trigger |
| `update` | `jobId`, `patch: {enabled}` | Toggle enabled/disabled |

## Requirements

- iOS 17+
- Xcode 16+
- No external dependencies

## License

Private — all rights reserved.
