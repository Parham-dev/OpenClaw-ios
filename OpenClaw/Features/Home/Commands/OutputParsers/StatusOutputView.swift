import SwiftUI

/// Parsed status output viewer with tables rendered as native rows.
struct StatusOutputView: View {
    let output: String

    private var result: StatusResult { StatusResult.parse(output) }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            ForEach(result.sections) { section in
                StatusSectionView(section: section)
            }

            // Footer hints
            ForEach(result.hints.indices, id: \.self) { i in
                Text(result.hints[i])
                    .font(AppTypography.captionMono)
                    .foregroundStyle(AppColors.primaryAction)
            }
        }
    }
}

// MARK: - Section View

private struct StatusSectionView: View {
    let section: StatusSection
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Button {
                withAnimation(.snappy(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text(section.title)
                        .font(AppTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text("(\(section.rows.count))")
                        .font(AppTypography.micro)
                        .foregroundStyle(AppColors.neutral)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(AppTypography.micro)
                        .foregroundStyle(AppColors.neutral)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                ForEach(section.rows) { row in
                    StatusRowView(row: row)
                }
            }
        }
    }
}

// MARK: - Row View

private struct StatusRowView: View {
    let row: StatusRow

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Text(row.key)
                .font(AppTypography.micro)
                .foregroundStyle(AppColors.neutral)
                .frame(width: 80, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                ForEach(row.values.indices, id: \.self) { i in
                    let val = row.values[i]
                    Text(val.text)
                        .font(val.isMono ? AppTypography.captionMono : AppTypography.caption)
                        .foregroundStyle(val.color)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Models

struct StatusSection: Identifiable {
    let id: String
    let title: String
    let rows: [StatusRow]
}

struct StatusRow: Identifiable {
    let id: String
    let key: String
    let values: [StatusValue]
}

struct StatusValue {
    let text: String
    let color: Color
    let isMono: Bool

    init(_ text: String) {
        self.text = text
        let lower = text.lowercased()
        if lower.contains("ok") || lower.contains("reachable") || lower.contains("on") || lower.contains("ready") || lower.contains("enabled") {
            self.color = AppColors.success
        } else if lower.contains("off") || lower.contains("not installed") || lower.contains("none") || lower.contains("unknown") || lower.contains("not ready") {
            self.color = AppColors.neutral
        } else if lower.contains("warn") || lower.contains("available") || lower.contains("missing") {
            self.color = AppColors.warning
        } else {
            self.color = .primary
        }
        self.isMono = text.contains("/") || text.contains("://") || text.contains(".json") || text.contains("~")
    }
}

// MARK: - Parser

struct StatusResult {
    let sections: [StatusSection]
    let hints: [String]

    static func parse(_ output: String) -> StatusResult {
        let lines = output.components(separatedBy: "\n")
        var sections: [StatusSection] = []
        var hints: [String] = []
        var currentTitle: String?
        var currentRows: [StatusRow] = []
        var headers: [String] = []
        var rowIndex = 0

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip empty and box borders
            if trimmed.isEmpty { continue }
            if trimmed.hasPrefix("┌") || trimmed.hasPrefix("├") || trimmed.hasPrefix("└") { continue }
            if trimmed.hasPrefix("▄") || trimmed.hasPrefix("▀") || trimmed.hasPrefix("█") { continue }
            if trimmed.contains("🦞") { continue }

            // Section titles (plain text before a table)
            if !trimmed.hasPrefix("│") && !trimmed.hasPrefix("─") {
                // Is this a section title? (short, no │, before a table)
                let isTitle = trimmed.count < 60 && !trimmed.contains(":") && trimmed.first?.isLetter == true
                    && !trimmed.hasPrefix("WARN") && !trimmed.hasPrefix("INFO") && !trimmed.hasPrefix("Fix")
                    && !trimmed.hasPrefix("Full") && !trimmed.hasPrefix("Deep") && !trimmed.hasPrefix("FAQ")
                    && !trimmed.hasPrefix("Troubl") && !trimmed.hasPrefix("Update") && !trimmed.hasPrefix("Next")
                    && !trimmed.hasPrefix("Need") && !trimmed.hasPrefix("Run")
                    && !trimmed.hasPrefix("Enabled") && !trimmed.hasPrefix("Permissive")

                if isTitle && trimmed != "OpenClaw status" {
                    // Flush previous section
                    if let title = currentTitle, !currentRows.isEmpty {
                        sections.append(StatusSection(id: title, title: title, rows: currentRows))
                        currentRows = []
                    }
                    currentTitle = trimmed
                    headers = []
                    continue
                }

                // Security audit inline — treat warn/info/fix as continuation text, skip for now
                if trimmed.hasPrefix("WARN") || trimmed.hasPrefix("INFO") || trimmed.hasPrefix("Fix:") || trimmed.hasPrefix("Summary:") {
                    // Add as a row to current section
                    if currentTitle != nil {
                        rowIndex += 1
                        currentRows.append(StatusRow(id: "inline-\(rowIndex)", key: "", values: [StatusValue(trimmed)]))
                    }
                    continue
                }

                // Hints
                if trimmed.hasPrefix("FAQ:") || trimmed.hasPrefix("Troubleshooting:") || trimmed.hasPrefix("Run:") || trimmed.hasPrefix("Need to") {
                    hints.append(trimmed)
                    continue
                }

                // Other non-table lines in a section
                if currentTitle != nil && !trimmed.isEmpty {
                    rowIndex += 1
                    currentRows.append(StatusRow(id: "text-\(rowIndex)", key: "", values: [StatusValue(trimmed)]))
                }
                continue
            }

            // Table rows (│ delimited)
            guard trimmed.hasPrefix("│") else { continue }

            let cells = trimmed.split(separator: "│").map { String($0).trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            if cells.isEmpty { continue }

            // Header row detection (first row after table border)
            if headers.isEmpty && cells.count >= 2 {
                headers = cells
                continue
            }

            // Data row
            if cells.count >= 2 {
                let key = cells[0]
                let value = cells.dropFirst().joined(separator: " · ")

                // Continuation row (empty key = append to previous)
                if key.isEmpty && !currentRows.isEmpty {
                    let prev = currentRows[currentRows.count - 1]
                    let combined = prev.values.map(\.text).joined(separator: " ") + " " + value
                    currentRows[currentRows.count - 1] = StatusRow(id: prev.id, key: prev.key, values: [StatusValue(combined)])
                } else {
                    rowIndex += 1
                    currentRows.append(StatusRow(id: "row-\(rowIndex)", key: key, values: [StatusValue(value)]))
                }
            }
        }

        // Flush last section
        if let title = currentTitle, !currentRows.isEmpty {
            sections.append(StatusSection(id: title, title: title, rows: currentRows))
        }

        return StatusResult(sections: sections, hints: hints)
    }
}
