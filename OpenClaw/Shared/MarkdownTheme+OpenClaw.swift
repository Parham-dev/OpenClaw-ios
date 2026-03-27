import MarkdownUI
import SwiftUI

extension Theme {
    /// Custom MarkdownUI theme matching the OpenClaw design system.
    static let openClaw = Theme()
        .text {
            ForegroundColor(.primary)
            FontSize(.em(0.9))
        }
        .heading1 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontWeight(.bold)
                    FontSize(.em(1.3))
                }
                .padding(.bottom, Spacing.xxs)
        }
        .heading2 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1.15))
                }
                .padding(.bottom, Spacing.xxs)
        }
        .heading3 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1.05))
                }
        }
        .strong {
            FontWeight(.semibold)
        }
        .emphasis {
            FontStyle(.italic)
        }
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(.em(0.88))
            BackgroundColor(AppColors.tintedBackground(.secondary, opacity: 0.12))
        }
        .codeBlock { configuration in
            ScrollView(.horizontal, showsIndicators: false) {
                configuration.label
                    .markdownTextStyle {
                        FontFamilyVariant(.monospaced)
                        FontSize(.em(0.85))
                    }
            }
            .padding(Spacing.sm)
            .background(AppColors.neutral.opacity(0.08), in: RoundedRectangle(cornerRadius: AppRadius.sm))
        }
        .blockquote { configuration in
            HStack(spacing: Spacing.xs) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppColors.neutral.opacity(0.3))
                    .frame(width: 3)
                configuration.label
                    .markdownTextStyle {
                        ForegroundColor(.secondary)
                        FontStyle(.italic)
                    }
            }
            .padding(.vertical, Spacing.xxs)
        }
        .link {
            ForegroundColor(AppColors.primaryAction)
        }
        .strikethrough {
            StrikethroughStyle(.single)
        }
        .listItem { configuration in
            configuration.label
                .padding(.vertical, 2)
        }
}
