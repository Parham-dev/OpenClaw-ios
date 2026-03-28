# OpenClaw

A native iOS control room for the OpenClaw AI gateway. Monitor system health, run commands, manage cron jobs, inspect agent execution traces, track token usage, browse agent memory and skills — all from your phone.

Built with SwiftUI and Swift Concurrency. One dependency: [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) for rendering LLM markdown output.

## Screens

| Tab | Description |
|-----|-------------|
| **Home** | Dashboard with 6 cards: System Health (live-polling ring gauges), Commands (quick actions with AI investigation), Cron Jobs (last/next run), Token Usage (today/yesterday/7d with model breakdown + tap for deep-dive analytics), Outreach Stats (grid), Blog Pipeline (published + stages). Chat icon (left nav bar) pushes to streaming chat. Settings via toolbar gear. |
| **Crons** | Segmented: **Cron Jobs** (full job list with status, schedule, manual run) and **History** (all recent runs across jobs, newest first). Tap job → detail view. Tap run → agent execution trace. |
| **Mem & Skills** | Segmented: **Memory** (browse workspace files — memory files, daily logs, reference) and **Skills** (browse skill folders with SKILL.md docs, scripts, configs). Markdown files support paragraph-level comments submitted to the AI agent. Non-markdown files shown read-only in monospace. |
| **Sessions** | Segmented: **Chat History** (main orchestrator session — newest messages first, full conversation trace) and **Subagents** (all spawned subagent sessions sorted by most recent, tap to view trace). |
| **More** | Placeholder for future features |

### Home Dashboard Cards

- **System Health** — CPU, RAM, Disk ring gauges with auto-polling every 15s (stops when not on Home tab). Uptime + load average.
- **Commands** — 6 quick action buttons (Doctor, Tail Logs, Security Audit, Backup, etc.). Each confirms before running, shows result in a modal with copy + "Investigate with AI" button. Tap "View Details" for full grid of all 12 commands + admin panels (Models & Config, Channels & Provider Usage). Manual refresh button on System Health card.
- **Cron Summary** — Last run status + next upcoming run at a glance.
- **Token Usage** — Segmented control (Today/Yesterday/7 Days). Total tokens, cost, proportional bar (input/output/cache read/cache write), request counts (total/thinking/tool), collapsible per-model breakdown. Tap "View Details" for deep-dive analytics with donut chart, cache efficiency gauge, cost-by-model bar chart, expanded per-model breakdowns, and per-pipeline token attribution.
- **Outreach Stats** — 6-cell grid with leads, channels, conversions.
- **Blog Pipeline** — Published count, active pipeline stage pills, last published link.

### Cron Detail View

- **Header** — status badge, enable/disable toggle (with confirmation), "Run Now" button (with confirmation)
- **Schedule** — human-readable frequency, raw cron expression, timezone
- **Timing** — last run with status + error message, next run with absolute date, consecutive errors
- **Investigate with AI** — when a job has errors, a bold action button sends the error to the orchestrator agent. The agent checks logs, diagnoses root cause, and fixes the issue if possible. Shows live elapsed timer during investigation, then a structured report (Status/Root Cause/Action Taken/Impact) with copy button. Latest investigation saved locally per job — "Last investigated X ago" link to reopen without re-running.
- **Run History** — paginated (20 per page). Each entry: status, time, duration, model badge, total tokens, token breakdown bar (input/output/cache). Tap to expand markdown summary. Tap row to open trace.

### Token Detail Page

- **Summary Grid** — 2-column metrics: total tokens, cost, input, output, cache read, cache write, requests, tool use
- **Charts** — donut chart (token type split), cache hit rate ring gauge, cost-by-model horizontal bar chart
- **By Model** — expanded cards per model with full token breakdown bars, thinking/tool/cache stats, cost (or "Included" for Copilot models)
- **By Pipeline** — client-side aggregation of cron run tokens. Proportional bars showing each pipeline's share of total usage. Blog jobs grouped into one pipeline.

### Agent Execution Trace

Full step-by-step trace of agent execution with metadata pills (model, provider, stop reason, tokens):
- **System Prompt** — initial instructions
- **Input Prompt** — the message that triggered the run
- **Thinking** — model reasoning (markdown)
- **Tool calls** — tool name + arguments
- **Tool results** — stdout/stderr output
- **Text responses** — final agent output (markdown)

### Commands & Admin Detail

- **Full command grid** — all 12 action commands in a 3-column grid with confirmation alerts
- **Models & Config** — default model with provider, fallbacks, image model, agent info (emoji + name), collapsible aliases list. Data from `models-status` + `agents-list` exec commands.
- **Channels** — connected channel status (Telegram, WhatsApp, etc.) with green/grey dots. Provider usage with quota progress bars and warning colors at 70%/90% thresholds. Data from `channels-list` exec command.
- All three admin sections load in parallel on appear.

### Mem & Skills Tab

- **Memory segment** — workspace files grouped by type (Memory Files, Daily Logs, Reference). Markdown rendered paragraph by paragraph. Add Figma-style comments on paragraphs, submit to the AI agent to perform edits. Page-level comment button (💬) to instruct the agent about the whole file.
- **Skills segment** — browse skill folders (blog-researcher, skill-reddit, outreach-email, etc.). Each skill shows its file tree: documents (.md) open in the full paragraph viewer with comments, scripts and configs (.py, .json, etc.) open in a read-only monospace viewer with copy button. Skill-level comment button sends instructions to the agent — the agent reads `create-skill` first (best practices), then the target skill, before acting. All skill file reading via `skill-read` exec command.
- **Comment system** — three levels: paragraph (inline), page (whole file), skill (whole skill). All share the same `CommentInputBar` and `CommentSheet` UI. Paragraph comments queue and batch-submit with swipe-to-delete. Page and skill comments submit immediately.

### Sessions Tab

- **Chat History** — the main orchestrator session (`agent:orchestrator:main`). Shows model, total tokens, cost, subagent count, status (running/idle). Tap to view the full conversation trace with newest messages first.
- **Subagents** — all spawned subagent sessions sorted by most recent. Each shows display name, model, tokens, last updated. Tap to view execution trace (chronological order).
- Uses `sessions_list` via `/tools/invoke` for the list, `sessions_history` for individual traces. Cron persistent sessions are filtered out (already covered in Crons tab).

### Chat

Accessible from the Home tab's left nav bar icon. Full streaming chat with the orchestrator agent.

- **SSE streaming** — real-time token-by-token response via `stream: true` on `/v1/chat/completions`
- **Session-bound** — uses `x-openclaw-session-key: agent:orchestrator:main`, agent has full conversation history server-side
- **History on open** — loads last 50 messages from session history (user + assistant text only, no tool calls). Reload button in toolbar to fetch latest.
- **Chat bubbles** — user messages (blue, right-aligned), assistant responses (markdown-rendered, left-aligned). Auto-scrolls during streaming.
- **Streaming indicator** — "Thinking..." spinner while waiting, green dot + "Streaming" while receiving
- **Stop button** — cancel stream mid-response (agent keeps running server-side). Shown in place of reload button during streaming.
- **Keyboard** — interactive scroll-to-dismiss, reuses `CommentInputBar`

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
| GET | `/stats/tokens?period=` | Token usage with full model breakdown |
| POST | `/stats/exec` | Run predefined safe commands (allowlisted) |
| POST | `/tools/invoke` | Gateway tool calls (see below) |
| POST | `/v1/chat/completions` | Send prompts to agent (used for memory edits, investigations) |

### Tool Actions (via /tools/invoke)

| Tool | Action | Args | Purpose |
|------|--------|------|---------|
| `cron` | `list` | `includeDisabled: true` | List all cron jobs |
| `cron` | `runs` | `jobId`, `limit`, `offset` | Paginated run history |
| `cron` | `run` | `jobId` | Manual trigger |
| `cron` | `update` | `jobId`, `patch: {enabled}` | Toggle enabled/disabled |
| `gateway` | `restart` | — | Restart gateway process |
| `sessions_list` | — | `limit` | List all sessions (response wrapped: `{count, sessions}`) |
| `sessions_history` | — | `sessionKey`, `limit`, `includeTools` | Agent execution trace |
| `memory_get` | — | `path`, `sessionKey` | Read workspace file content |

### Stats Exec Commands (via /stats/exec)

Predefined server-side allowlist: `doctor`, `status`, `logs`, `security-audit`, `backup`, `channels-status`, `config-validate`, `memory-reindex`, `session-cleanup`, `plugin-update`, `memory-list`, `skills-list`, `skill-files` (takes skill name), `skill-read` (takes "skillId relativePath"), `models-status`, `agents-list`, `channels-list`.

### Gateway Config Required

- `tools.sessions.visibility = "all"` — allows reading cron run session traces
- `tools.profile = "full"` — enables sessions_history, sessions_list, memory_get
- `memorySearch.extraPaths` — must include workspace root for accessing all `.md` files
- `gateway.http.endpoints.chatCompletions.enabled = true` — for agent-mediated edits and investigations

## Requirements

- iOS 17+
- Xcode 16+
- MarkdownUI via SPM

## License

Private — all rights reserved.
