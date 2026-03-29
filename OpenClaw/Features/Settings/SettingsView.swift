import SwiftUI

struct SettingsView: View {
    let keychain: KeychainService
    var client: GatewayClientProtocol?

    @State private var showTokenSetup = false
    @State private var isTesting = false
    @State private var testResult: TestResult?

    var body: some View {
        List {
            // Auth
            Section {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: keychain.hasToken ? "lock.fill" : "lock.open")
                        .foregroundStyle(keychain.hasToken ? AppColors.success : AppColors.danger)
                    Text("Bearer Token")
                    Spacer()
                    if keychain.hasToken {
                        Text("Configured")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.success)
                    } else {
                        Text("Not Set")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.danger)
                    }
                }

                Button {
                    showTokenSetup = true
                } label: {
                    Text(keychain.hasToken ? "Replace Token\u{2026}" : "Set Token\u{2026}")
                }
            } header: {
                Text("Authentication")
            } footer: {
                Text("Stored in the device Keychain. Never written to UserDefaults or iCloud.")
                    .font(AppTypography.micro)
            }

            // Gateway info
            Section("Gateway") {
                LabeledContent("URL", value: "api.appwebdev.co.uk")
                LabeledContent("Agent", value: AppConstants.agentId.capitalized)
                LabeledContent("TLS", value: "Auto-renewal")
            }

            // Connection test
            Section {
                Button(action: runConnectionTest) {
                    HStack {
                        Label("Test Connection", systemImage: "network")
                        Spacer()
                        if isTesting { ProgressView().scaleEffect(0.8) }
                    }
                }
                .disabled(isTesting || !keychain.hasToken)

                if let result = testResult {
                    Label(result.message, systemImage: result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(AppTypography.captionMono)
                        .foregroundStyle(result.isSuccess ? AppColors.success : AppColors.danger)
                        .textSelection(.enabled)
                }
            } header: {
                Text("Diagnostics")
            } footer: {
                Text("Sends a live request to the gateway and shows the server response.")
                    .font(AppTypography.micro)
            }

            // App info
            Section("About") {
                LabeledContent("App", value: "OpenClaw")
                LabeledContent("Platform", value: "iOS 17+")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTokenSetup) {
            TokenSetupView(keychain: keychain) {
                showTokenSetup = false
            }
        }
    }

    private func runConnectionTest() {
        isTesting = true
        testResult = nil
        let testClient = client ?? GatewayClient(keychain: keychain)
        Task {
            do {
                let dto: SystemStatsDTO = try await testClient.stats("stats/system")
                testResult = TestResult(
                    isSuccess: true,
                    message: "OK \u{2014} CPU \(String(format: "%.1f", dto.cpuPercent))%  RAM \(dto.ramPercent)%"
                )
                Haptics.shared.success()
            } catch {
                testResult = TestResult(isSuccess: false, message: error.localizedDescription)
                Haptics.shared.error()
            }
            isTesting = false
        }
    }
}

private struct TestResult {
    let isSuccess: Bool
    let message: String
}
