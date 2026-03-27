# OpenClaw

A native iOS control room for the OpenClaw AI gateway. Monitor system health, manage cron jobs, inspect agent execution traces, track outreach metrics, and oversee your blog pipeline — all from your phone.

Built with SwiftUI and Swift Concurrency. One dependency: [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) for rendering LLM markdown output.

## Screens

| Tab | Description |
|-----|-------------|
| **Home** | Dashboard with 4 summary cards: System Health (ring gauges), Cron Jobs (last/next run), Outreach Stats (grid), Blog Pipeline (published count + stages). Settings via toolbar gear. |
| **Crons** | Full job list with status badges, human-readable schedules, last/next run times, manual run button. Tap → detail view → tap a run → agent execution trace. |
| **Pipelines** | Coming soon — live per-pipeline cards (Blog, Outreach, WhatsApp, Site Agent) |
| **Memory** | Coming soon — browse and edit workspace files (MEMORY.md, daily notes, skills) |
| **Chat** | Coming soon — streaming conversations with your AI agent via SSE |

### Cron Detail View

Each cron job has a dedicated detail screen:
- **Header** — status badge, enable/disable toggle, "Run Now" button
- **Schedule** — human-readable frequency, raw cron expression, timezone
- **Timing** — last run with status, next run with absolute date, error details
- **Run History** — paginated list (20 per page, load more). Each entry shows: status dot, relative/absolute time, duration, model badge, total tokens, and a token breakdown bar (input/output/reasoning proportions with colored legend). Tap to expand full markdown summary.

### Agent Execution Trace

Tap any run with a session → full step-by-step trace of the agent's execution:
- **Thinking** — model reasoning (rendered as markdown)
- **Tool calls** — tool name + arguments
- **Tool results** — stdout/stderr output
- **Text responses** — final agent output (rendered as markdown)

Each step is collapsible with a preview line when collapsed.

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
| POST | `/tools/invoke` | Tool calls (see below) |

### Tool Actions

| Tool | Action | Args | Purpose |
|------|--------|------|---------|
| `cron` | `list` | — | List all cron jobs |
| `cron` | `runs` | `jobId`, `limit`, `offset` | Paginated run history |
| `cron` | `run` | `jobId` | Manual trigger |
| `cron` | `update` | `jobId`, `patch: {enabled}` | Toggle enabled/disabled |
| `sessions_history` | — | `sessionKey`, `limit`, `includeTools` | Agent execution trace |

### Gateway Config Required

- `tools.sessions.visibility = "all"` — allows reading cron run session traces
- `tools.profile = "full"` — enables sessions_history and sessions_list tools

## Requirements

- iOS 17+
- Xcode 16+
- MarkdownUI via SPM

## License

Private — all rights reserved.
