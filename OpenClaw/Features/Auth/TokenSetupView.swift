import SwiftUI

struct TokenSetupView: View {
    let keychain: KeychainService
    let onTokenSaved: () -> Void

    @State private var tokenInput = ""
    @State private var errorMessage: String?
    @State private var isSaving = false

    var body: some View {
        VStack(spacing: Spacing.lg + 4) {
            Spacer()

            Image(systemName: "key.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppColors.warning)

            VStack(spacing: Spacing.xs) {
                Text("Connect to Gateway")
                    .font(AppTypography.screenTitle)
                Text("Enter your Bearer token to connect to the OpenClaw gateway at api.appwebdev.co.uk.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.neutral)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: Spacing.xs - 2) {
                Text("BEARER TOKEN")
                    .font(AppTypography.micro)
                    .foregroundStyle(AppColors.neutral)
                    .tracking(AppTypography.sectionLabelTracking)

                SecureField("Paste token here\u{2026}", text: $tokenInput)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(Spacing.sm)
                    .background(AppColors.neutral.opacity(0.1), in: RoundedRectangle(cornerRadius: AppRadius.md))
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: saveToken) {
                Group {
                    if isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text("Connect")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(Spacing.sm + 2)
            }
            .background(AppColors.primaryAction, in: RoundedRectangle(cornerRadius: AppRadius.lg))
            .foregroundStyle(.white)
            .disabled(tokenInput.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)

            Spacer()
        }
        .padding(Spacing.xl)
    }

    private func saveToken() {
        let trimmed = tokenInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isSaving = true
        errorMessage = nil

        do {
            try keychain.saveToken(trimmed)
            onTokenSaved()
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
        }
    }
}
