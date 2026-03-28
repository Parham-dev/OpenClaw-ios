import SwiftUI

struct ModelsSection: View {
    let config: ModelsConfig
    let agents: [AgentInfo]
    @State private var showAliases = false

    var body: some View {
        Section("Models & Config") {
            // Default model
            ModelRow(label: "Default", model: config.defaultModel)

            // Fallbacks
            if !config.fallbacks.isEmpty {
                ForEach(config.fallbacks, id: \.self) { fb in
                    ModelRow(label: "Fallback", model: fb)
                }
            }

            // Image model
            if let imageModel = config.imageModel {
                ModelRow(label: "Image", model: imageModel)
            } else {
                HStack {
                    Text("Image")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.neutral)
                    Spacer()
                    Text("None")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.neutral)
                }
            }

            // Agent info
            ForEach(agents) { agent in
                HStack(spacing: Spacing.xs) {
                    Text(agent.emoji)
                    Text(agent.name)
                        .font(AppTypography.body)
                        .fontWeight(.medium)
                    if agent.isDefault {
                        Text("Default")
                            .font(AppTypography.nano)
                            .padding(.horizontal, Spacing.xxs)
                            .padding(.vertical, 2)
                            .background(AppColors.success.opacity(0.15), in: Capsule())
                            .foregroundStyle(AppColors.success)
                    }
                    Spacer()
                    if let model = agent.model {
                        ModelPill(model: model)
                    }
                }
            }

            // Aliases — collapsible
            if !config.aliases.isEmpty {
                Button {
                    withAnimation(.snappy(duration: 0.3)) {
                        showAliases.toggle()
                    }
                } label: {
                    HStack {
                        Text("Aliases (\(config.aliases.count))")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.primaryAction)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(AppTypography.micro)
                            .foregroundStyle(AppColors.primaryAction)
                            .rotationEffect(.degrees(showAliases ? 180 : 0))
                    }
                }
                .buttonStyle(.plain)

                if showAliases {
                    ForEach(config.aliases, id: \.name) { alias in
                        ModelRow(label: alias.name, model: alias.model)
                    }
                }
            }
        }
    }
}

/// Row showing a label + provider + model pill.
private struct ModelRow: View {
    let label: String
    let model: String

    private var provider: String? {
        guard model.contains("/") else { return nil }
        return String(model.split(separator: "/").first ?? "")
            .replacingOccurrences(of: "github-copilot", with: "Copilot")
            .replacingOccurrences(of: "anthropic", with: "Anthropic")
    }

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.neutral)
            Spacer()
            if let provider {
                Text(provider)
                    .font(AppTypography.micro)
                    .foregroundStyle(AppColors.neutral)
            }
            ModelPill(model: model)
        }
    }
}
