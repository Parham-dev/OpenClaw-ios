# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

- Never build automatically — user runs manually via Xcode.
- **Project**: `OpenClaw.xcodeproj` (no workspace)
- **Dependencies**: MarkdownUI via SPM (`https://github.com/gonzalezreal/swift-markdown-ui`)
- **Bundle ID**: `co.uk.appwebdev.OpenClaw`
- **Deployment**: iOS 17+, Swift 6 patterns (`@Observable`, strict `Sendable`)

## Architecture

Clean Architecture with MVVM per feature, protocol-based DI, and a generic ViewModel base.

### Layer flow

```
View → LoadableViewModel<T> → Repository protocol → GatewayClientProtocol → URLSession
                                      ↓
                                 MemoryCache (actor, TTL)
```

### Key abstractions

- **`LoadableViewModel<T>`** (`Core/LoadableViewModel.swift`): `@Observable @MainActor` base. Handles `data`, `isLoading`, `error`, `isStale`, `start()`, `refresh()`, `cancel()` with structured Task management. Feature VMs are one-liner subclasses.

- **`GatewayClientProtocol`** (`Core/GatewayClient.swift`): `stats()` (GET, uses `.convertFromSnakeCase`) and `invoke()` (POST, camelCase — no snake_case conversion). Concrete `GatewayClient` is a `Sendable` struct.

- **Repository protocols** (`Core/Repositories/`): One per feature. `Remote*Repository` owns a `MemoryCache<T>` actor and maps DTO→domain. `CronDetailRepository` supports paginated runs and session trace fetching.

- **DTOs vs Domain models**: `Decodable` types in `Core/Networking/DTOs/` (suffixed `DTO`). Domain models in feature folders with `init(dto:)` mappers. Domain types use `Date`, `URL?` etc.

### Navigation

`ContentView` (auth gate) → `MainTabView` (5 tabs): Home, Crons, Pipelines (placeholder), Memory (placeholder), Chat (placeholder). Settings accessed via Home toolbar gear icon.

Shared state: `CronSummaryViewModel` and `CronDetailRepository` created once in `MainTabView`, shared across tabs.

Navigation depth: Crons tab → `CronDetailView` → tap run → `SessionTraceView`.

### Design system

All views use semantic tokens — never raw literals:
- `Spacing` — 4pt grid (xxs=4 through xxl=48)
- `AppColors` — `.success`, `.danger`, `.metricPrimary`, `.gauge(percent:warn:critical:)`
- `AppTypography` — Dynamic Type styles (`.heroNumber`, `.cardTitle`, `.actionIcon`, `.badgeIcon`)
- `AppRadius` — `.sm`(8), `.md`(10), `.lg`(12), `.card`(16)
- `Formatters` — cached `RelativeDateTimeFormatter` and `DateFormatter`

### Shared components

- `CronStatusDot` / `CronStatusBadge` (`Shared/CronStatusViews.swift`) — reused across cron list, detail, and trace views. Badge supports `.small` and `.large` styles.
- `TokenBreakdownBar` (`Features/Crons/TokenBreakdownBar.swift`) — proportional bar + legend showing input/output/reasoning token split.
- `CardContainer`, `CardLoadingView`, `CardErrorView` — standard card shells for dashboard.

## Conventions

- **New features**: DTO in `Core/Networking/DTOs/`, domain model in feature folder with `init(dto:)`, repository protocol + `Remote*` in `Core/Repositories/`, VM subclass of `LoadableViewModel<T>`, view using `CardContainer` for dashboard cards.
- **Concurrency**: `@MainActor` on all ViewModels. `@Sendable` closures for loaders. Actor-based `MemoryCache`. No `@unchecked Sendable`.
- **Logging**: `os.Logger` (subsystem: `co.uk.appwebdev.openclaw`), never `print()`.
- **Accessibility**: All custom visual components need `.accessibilityElement` + `.accessibilityLabel`.
- **Haptics**: `Haptics.shared` for user action feedback (refresh, save, errors).
- **UI**: Design tokens only. Skeleton shimmer via `.shimmer()`. `CardLoadingView`/`CardErrorView` for card states.
- **File size**: Keep files under 300 lines. Extract components into separate files when a view grows beyond that.
- **Pagination**: Large lists must use limit/offset with "Load More" button. Deduplicate on append by ID. See `CronDetailViewModel` for the pattern.
- **Formatters**: Always use `Formatters.relativeString(for:)` / `Formatters.absoluteString(for:)`. Never instantiate formatters inline.
- **Markdown**: Use `Markdown(text).markdownTheme(.openClaw)` from MarkdownUI for LLM-generated content. Never use `AttributedString(markdown:)`. MarkdownUI v2 does not support `.table` theme customization.

## Gateway API Gotchas

- **`stats()` vs `invoke()`**: GET endpoints use snake_case JSON keys (decoder uses `.convertFromSnakeCase`). POST `/tools/invoke` responses use camelCase — no conversion. Only add `CodingKeys` for nested snake_case fields (e.g. `Usage.input_tokens`).
- **Cron schedules**: Jobs can be `kind: "cron"` (has `expr`) or `kind: "every"` (has `everyMs`, no `expr`). DTO `expr` field must be optional.
- **Session history**: Uses `sessions_history` tool (not `sessions`). Takes `sessionKey` (full format like `agent:orchestrator:subagent:UUID`), not `sessionId` (bare UUID). Cron run DTOs may have either or both — domain model stores both, trace view tries `sessionKey` first.
- **Gateway config**: Requires `tools.sessions.visibility = "all"` for cross-session trace access, and `tools.profile = "full"` for session tools.
- **Error responses**: The gateway returns `{"status":"error","error":"..."}` or `{"status":"forbidden","error":"..."}` which don't match DTOs — these fail at decode. The `invoke()` method throws `GatewayError.httpError` for HTTP errors, but in-envelope errors (200 OK with error payload) surface as decode failures. Handle gracefully in VMs.
