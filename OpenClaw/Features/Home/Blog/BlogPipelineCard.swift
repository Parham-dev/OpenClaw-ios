import SwiftUI

struct BlogPipelineCard: View {
    let vm: BlogPipelineViewModel

    var body: some View {
        CardContainer(
            title: "Blog Pipeline",
            systemImage: "doc.text.fill",
            isStale: vm.isStale,
            isLoading: vm.isLoading && vm.data == nil
        ) {
            if let s = vm.data {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    // Hero published count
                    HStack(alignment: .bottom, spacing: Spacing.xs) {
                        Text("\(s.published)")
                            .font(AppTypography.heroNumber)
                            .contentTransition(.numericText())
                        Text("Published")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.neutral)
                            .padding(.bottom, Spacing.xs)
                        Spacer()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(s.published) articles published")

                    // Active pipeline pills
                    if !s.activePipeline.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.xs) {
                                ForEach(s.activePipeline, id: \.label) { item in
                                    PipelinePill(label: item.label, count: item.count)
                                }
                            }
                        }
                    }

                    // Last published link
                    if let title = s.lastPublishedTitle,
                       let urlString = s.lastPublishedUrl,
                       let url = URL(string: urlString) {
                        Divider()
                        Link(destination: url) {
                            HStack(alignment: .top, spacing: Spacing.xs) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("LAST PUBLISHED")
                                        .font(AppTypography.micro)
                                        .foregroundStyle(AppColors.neutral)
                                        .tracking(AppTypography.sectionLabelTracking)
                                    Text(title)
                                        .font(AppTypography.caption)
                                        .foregroundStyle(AppColors.primaryAction)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColors.primaryAction)
                                    .padding(.top, Spacing.sm + 2)
                            }
                        }
                        .accessibilityLabel("Last published: \(title)")
                    }
                }
            } else if vm.isLoading {
                CardLoadingView(minHeight: 100)
            } else if let err = vm.error {
                CardErrorView(error: err, minHeight: 100)
            }
        }
    }
}

private struct PipelinePill: View {
    let label: String
    let count: Int

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Text("\(count)")
                .font(AppTypography.captionBold)
            Text(label)
                .font(AppTypography.caption)
        }
        .padding(.horizontal, Spacing.xs + 2)
        .padding(.vertical, Spacing.xxs + 1)
        .background(AppColors.pillBackground, in: Capsule())
        .foregroundStyle(AppColors.pillForeground)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) \(label)")
    }
}
