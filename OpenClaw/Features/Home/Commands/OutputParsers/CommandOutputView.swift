import SwiftUI

/// Routes command output to the appropriate parsed view.
/// Falls back to raw monospace text for commands without a custom parser.
struct CommandOutputView: View {
    let commandId: String
    let output: String

    var body: some View {
        switch commandId {
        case "tail-logs":
            LogOutputView(output: output)
        case "security-audit":
            SecurityAuditView(output: output)
        case "doctor":
            DoctorOutputView(output: output)
        case "gateway-status":
            StatusOutputView(output: output)
        case "channel-status":
            ChannelStatusView(output: output)

        default:
            // Raw fallback
            Text(output)
                .font(AppTypography.captionMono)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.sm)
                .background(AppColors.neutral.opacity(0.08), in: RoundedRectangle(cornerRadius: AppRadius.sm))
        }
    }
}
