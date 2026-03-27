# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
# Build for simulator
xcodebuild -scheme OpenClaw -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests (none exist yet — create with XCTest, no SPM test runner)
xcodebuild -scheme OpenClaw -destination 'platform=iOS Simulator,name=iPhone 16' test
```

No external dependencies. No Package.swift, CocoaPods, or SPM packages. Pure Apple frameworks only.

- **Xcode project**: `OpenClaw.xcodeproj` (no workspace)
- **Bundle ID**: `co.uk.appwebdev.OpenClaw`
- **Deployment target**: iOS 17+
- **Swift version**: Uses Swift 6 patterns (@Observable, strict Sendable) though project file says 5.0

## Architecture

**Clean Architecture with MVVM per feature, protocol-based DI, and a generic ViewModel base.**

### Layer flow
```
View → ViewModel (LoadableViewModel<T>) → Repository protocol → GatewayClient → URLSession
                                              ↓
                                         MemoryCache (actor, TTL-based)
```

### Key abstractions

- **`LoadableViewModel<T>`** (`Core/LoadableViewModel.swift`): Generic `@Observable @MainActor` base class. Handles `data`, `isLoading`, `error`, `isStale`, `start()`, `refresh()`, `cancel()`. All 4 feature VMs are one-liner subclasses that pass a loader closure.

- **`GatewayClientProtocol`** (`Core/GatewayClient.swift`): Two methods — `stats()` (GET) and `invoke()` (POST with wrapped response envelope). Concrete `GatewayClient` is a `Sendable` struct.

- **Repository protocols** (`Core/Repositories/`): One per feature (`SystemHealthRepository`, `CronRepository`, etc.). Concrete `Remote*Repository` implementations own a `MemoryCache<T>` actor and handle DTO→domain mapping.

- **DTOs vs Domain models**: Network `Decodable` types live in `Core/Networking/DTOs/` (suffixed `DTO`). Domain models live in each feature folder and have `init(dto:)` mappers. Domain models use richer types (`Date` instead of `Int` timestamps, `URL?` instead of `String?`).

### Navigation structure

`ContentView` (auth gate) → `MainTabView` (5 tabs):
1. **Home** — dashboard with 4 summary cards (System, Cron, Outreach, Blog) + Settings gear in toolbar
2. **Crons** — full job list (shares `CronSummaryViewModel` with Home's cron card)
3. **Pipelines** — placeholder
4. **Memory** — placeholder
5. **Chat** — placeholder

The `CronSummaryViewModel` is created once in `MainTabView` and shared between the Home card and Crons tab to avoid duplicate network calls.

### Design system

All views use semantic tokens — never raw color/spacing/font literals:
- `Spacing` — 4pt grid (xxs through xxl)
- `AppColors` — semantic names (`.success`, `.danger`, `.metricPrimary`, `.gauge(percent:warn:critical:)`)
- `AppTypography` — Dynamic Type styles (`.heroNumber`, `.cardTitle`, `.metricValue`, etc.)
- `AppRadius` — corner radius tokens (`.sm`, `.card`, etc.)

### Gateway API

All requests go to `https://api.appwebdev.co.uk` with `Authorization: Bearer <token>` (stored in iOS Keychain via `KeychainService`).

| Method | Path | Returns |
|--------|------|---------|
| GET | `/stats/system` | `SystemStatsDTO` |
| GET | `/stats/outreach` | `OutreachStatsDTO` |
| GET | `/stats/blog` | `BlogStatsDTO` |
| POST | `/tools/invoke` | Wrapped JSON (`result.content[0].text`) — used for cron list |

## Conventions

- **Concurrency**: `@MainActor` on all ViewModels. `@Sendable` closures for loaders. Actor-based `MemoryCache`. No `@unchecked Sendable`.
- **New features**: Follow the existing pattern — DTO in `Core/Networking/DTOs/`, domain model in feature folder with `init(dto:)`, repository protocol + `Remote*` implementation in `Core/Repositories/`, VM subclass of `LoadableViewModel<T>`, card view using `CardContainer`.
- **Logging**: Use `os.Logger` (subsystem: `co.uk.appwebdev.openclaw`), never `print()`.
- **Accessibility**: All custom visual components need `.accessibilityElement` + `.accessibilityLabel`.
- **Haptics**: Use `Haptics.shared` for feedback on user actions (refresh, save, errors).
