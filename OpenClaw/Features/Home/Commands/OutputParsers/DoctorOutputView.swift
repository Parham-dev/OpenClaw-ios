import SwiftUI

/// Parsed doctor output viewer with collapsible sections.
struct DoctorOutputView: View {
    let output: String

    private var result: DoctorResult { DoctorResult.parse(output) }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Status lines (outside boxes)
            if !result.statusLines.isEmpty {
                ForEach(result.statusLines.indices, id: \.self) { i in
                    let line = result.statusLines[i]
                    HStack(spacing: Spacing.xs) {
                        if line.contains(": ok") {
                            Image(systemName: "checkmark.circle.fill")
                                .font(AppTypography.micro)
                                .foregroundStyle(AppColors.success)
                        } else {
                            Image(systemName: "info.circle.fill")
                                .font(AppTypography.micro)
                                .foregroundStyle(AppColors.neutral)
                        }
                        Text(line)
                            .font(AppTypography.caption)
                    }
                }
            }

            // Sections
            ForEach(result.sections) { section in
                DoctorSectionRow(section: section)
            }

            // Fix hint
            if let fixHint = result.fixHint {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "wrench.and.screwdriver")
                        .foregroundStyle(AppColors.primaryAction)
                    Text(fixHint)
                        .font(AppTypography.captionMono)
                        .foregroundStyle(AppColors.primaryAction)
                }
                .padding(Spacing.xs)
                .background(AppColors.tintedBackground(AppColors.primaryAction), in: RoundedRectangle(cornerRadius: AppRadius.sm))
            }
        }
    }
}

// MARK: - Section Row

private struct DoctorSectionRow: View {
    let section: DoctorSection
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Button {
                withAnimation(.snappy(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: section.icon)
                        .font(AppTypography.caption)
                        .foregroundStyle(section.color)
                        .frame(width: 16)
                    Text(section.title)
                        .font(AppTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    if !section.items.isEmpty {
                        Text("(\(section.items.count))")
                            .font(AppTypography.micro)
                            .foregroundStyle(AppColors.neutral)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(AppTypography.micro)
                        .foregroundStyle(AppColors.neutral)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                ForEach(section.items.indices, id: \.self) { i in
                    Text(section.items[i])
                        .font(AppTypography.micro)
                        .foregroundStyle(AppColors.neutral)
                        .padding(.leading, 24)
                }
            }
        }
        .padding(.vertical, Spacing.xxs)
    }
}

// MARK: - Models + Parser

struct DoctorSection: Identifiable {
    let id: String
    let title: String
    let items: [String]

    var icon: String {
        switch title.lowercased() {
        case let t where t.contains("startup"):   "bolt"
        case let t where t.contains("state"):     "externaldrive"
        case let t where t.contains("security"):  "lock.shield"
        case let t where t.contains("skill"):     "bolt.circle"
        case let t where t.contains("plugin"):    "puzzlepiece"
        case let t where t.contains("memory"):    "brain"
        default: "stethoscope"
        }
    }

    var color: Color {
        if items.isEmpty { return AppColors.success }
        let text = items.joined()
        if text.contains("missing") || text.contains("not set") || text.contains("not ready") { return AppColors.warning }
        if text.contains("error") || text.contains("Error") { return AppColors.danger }
        return AppColors.neutral
    }
}

struct DoctorResult {
    let sections: [DoctorSection]
    let statusLines: [String]
    let fixHint: String?

    static func parse(_ output: String) -> DoctorResult {
        let lines = output.components(separatedBy: "\n")
        var sections: [DoctorSection] = []
        var statusLines: [String] = []
        var fixHint: String?

        var currentTitle: String?
        var currentItems: [String] = []
        var inBox = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip empty, box art, ASCII header
            if trimmed.isEmpty { continue }
            if trimmed.hasPrefix("▄") || trimmed.hasPrefix("▀") || trimmed.hasPrefix("█") { continue }
            if trimmed.contains("🦞") { continue }
            if trimmed == "---" { continue }
            if trimmed.hasPrefix("[skills]") { continue }

            // Section header: ◇  Title ──
            if trimmed.contains("◇") {
                // Flush previous section
                if let title = currentTitle {
                    sections.append(DoctorSection(id: title, title: title, items: currentItems))
                    currentItems = []
                }
                // Extract title between ◇ and ─
                let afterDiamond = trimmed.split(separator: "◇", maxSplits: 1).last.map(String.init) ?? trimmed
                let beforeLine = afterDiamond.split(separator: "─").first.map(String.init) ?? afterDiamond
                currentTitle = beforeLine.trimmingCharacters(in: .whitespaces)
                inBox = true
                continue
            }

            // Box borders — skip
            if trimmed.hasPrefix("┌") || trimmed.hasPrefix("├") || trimmed.hasPrefix("└") { continue }
            if trimmed == "│" || trimmed.hasSuffix("╮") || trimmed.hasSuffix("╯") { continue }

            // Fix hint
            if trimmed.hasPrefix("Run \"openclaw doctor") || trimmed.hasPrefix("Run 'openclaw doctor") {
                fixHint = trimmed
                continue
            }

            // Doctor complete footer
            if trimmed.contains("Doctor complete") { continue }

            // Content inside box
            if inBox && trimmed.hasPrefix("│") {
                var content = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
                // Strip trailing │ or box chars
                if content.hasSuffix("│") { content = String(content.dropLast()).trimmingCharacters(in: .whitespaces) }
                if content.isEmpty { continue }

                // Items starting with - are separate entries; others are continuations
                if content.hasPrefix("- ") {
                    currentItems.append(String(content.dropFirst(2)))
                } else if content.hasPrefix("Fix ") || content.hasPrefix("Fix:") {
                    currentItems.append("💡 " + content)
                } else if let last = currentItems.last {
                    currentItems[currentItems.count - 1] = last + " " + content
                } else {
                    currentItems.append(content)
                }
                continue
            }

            // Status lines outside boxes (Telegram: ok, Agents:, Session store:, etc.)
            if !inBox || currentTitle == nil {
                if trimmed.contains(":") && !trimmed.hasPrefix("│") {
                    statusLines.append(trimmed)
                }
            } else {
                // Lines between boxes (status lines after a box closes)
                if !trimmed.hasPrefix("│") && trimmed.contains(":") {
                    inBox = false
                    statusLines.append(trimmed)
                }
            }
        }

        // Flush last section
        if let title = currentTitle {
            sections.append(DoctorSection(id: title, title: title, items: currentItems))
        }

        return DoctorResult(sections: sections, statusLines: statusLines, fixHint: fixHint)
    }
}
