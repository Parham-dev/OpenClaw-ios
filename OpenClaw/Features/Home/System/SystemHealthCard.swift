import SwiftUI

struct SystemHealthCard: View {
    let vm: SystemHealthViewModel

    var body: some View {
        CardContainer(
            title: "System Health",
            systemImage: "desktopcomputer",
            isStale: vm.isStale,
            isLoading: vm.isLoading && vm.data == nil
        ) {
            if let s = vm.data {
                VStack(spacing: Spacing.sm + 2) {
                    HStack(spacing: 0) {
                        RingGauge(
                            value: s.cpuPercent / 100,
                            label: "CPU",
                            color: AppColors.gauge(percent: s.cpuPercent, warn: 60, critical: 80)
                        )
                        .frame(maxWidth: .infinity)

                        RingGauge(
                            value: s.ramPercent / 100,
                            label: "RAM",
                            color: AppColors.gauge(percent: s.ramPercent, warn: 70, critical: 85)
                        )
                        .frame(maxWidth: .infinity)

                        RingGauge(
                            value: s.diskPercent / 100,
                            label: "Disk",
                            color: AppColors.gauge(percent: s.diskPercent, warn: 80, critical: 90)
                        )
                        .frame(maxWidth: .infinity)
                    }

                    HStack {
                        Label(s.uptimeFormatted, systemImage: "clock")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.neutral)

                        Spacer()

                        HStack(spacing: Spacing.xxs) {
                            Text("Load")
                                .font(AppTypography.micro)
                                .foregroundStyle(AppColors.neutral)
                            Text(String(format: "%.2f", s.loadAvg1M))
                                .font(AppTypography.captionMono)
                                .contentTransition(.numericText())
                                .padding(.horizontal, Spacing.xs - 2)
                                .padding(.vertical, 2)
                                .background(AppColors.pillBackground, in: Capsule())
                                .foregroundStyle(AppColors.pillForeground)
                        }
                    }
                }
            } else if vm.isLoading {
                CardLoadingView(minHeight: 90)
            } else if let err = vm.error {
                CardErrorView(error: err, minHeight: 90)
            }
        }
    }
}
