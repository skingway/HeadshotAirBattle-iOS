import SwiftUI

// MARK: - SciFi Background

struct SciFiBgView<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        ZStack {
            AppColors.bgGradient.ignoresSafeArea()

            RadialGradient(
                colors: [Color(red: 0, green: 100/255, blue: 200/255).opacity(0.15), .clear],
                center: .topLeading,
                startRadius: 0, endRadius: 300
            ).ignoresSafeArea()

            content()
        }
    }
}

// MARK: - Card Views

struct CardView<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0, green: 30/255, blue: 60/255).opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppColors.accentBorder.opacity(0.5), lineWidth: 1)
            )
    }
}

struct CardHighlightView<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppColors.accentSoft)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppColors.accentBorder.opacity(0.8), lineWidth: 1)
            )
            .shadow(color: AppColors.accentGlow.opacity(0.15), radius: 15, x: 0, y: 0)
    }
}

// MARK: - Buttons

struct PrimaryButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(icon)
                Text(title.uppercased())
                    .font(AppFonts.buttonText)
                    .tracking(2)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.primaryGradient)
            )
            .shadow(color: AppColors.accentGlow.opacity(0.3), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct SecondaryButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(icon)
                Text(title.uppercased())
                    .font(AppFonts.buttonText)
                    .tracking(2)
            }
            .foregroundColor(AppColors.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.accentSoft)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.accentBorder, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct TertiaryButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(icon)
                Text(title.uppercased())
                    .font(AppFonts.buttonText)
                    .tracking(2)
            }
            .foregroundColor(AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Tags

struct InfoTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppFonts.tag)
            .foregroundColor(Color.white.opacity(0.8))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(AppColors.accentDim)
            )
            .overlay(
                Capsule()
                    .stroke(AppColors.accentBorder, lineWidth: 1)
            )
    }
}

struct WinTag: View {
    var body: some View {
        Text("WIN")
            .font(AppFonts.orbitron(11, weight: .bold))
            .foregroundColor(AppColors.success)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(AppColors.successDim)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(AppColors.successBorder, lineWidth: 1)
            )
    }
}

struct LossTag: View {
    var body: some View {
        Text("LOSS")
            .font(AppFonts.orbitron(11, weight: .bold))
            .foregroundColor(AppColors.danger)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(AppColors.dangerDim)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(AppColors.dangerBorder, lineWidth: 1)
            )
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var color: Color = AppColors.accent

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(color)
                .frame(width: 3, height: 20)

            Text(title.uppercased())
                .font(AppFonts.sectionTitle)
                .foregroundColor(AppColors.textPrimary)
                .tracking(2)
                .padding(.leading, 12)
        }
        .padding(.top, 24)
        .padding(.bottom, 12)
    }
}

// MARK: - Divider

struct DividerLine: View {
    var body: some View {
        Rectangle()
            .fill(AppColors.divider)
            .frame(height: 1)
            .padding(.vertical, 4)
    }
}

// MARK: - Grid Cell Colors

struct GridCellColors {
    static let water = Color(red: 0, green: 50/255, blue: 100/255).opacity(0.3)
    static let ship = AppColors.accent.opacity(0.3)
    static let hit = AppColors.danger.opacity(0.5)
    static let miss = Color.gray.opacity(0.2)
    static let cornerRadius: CGFloat = 2
    static let spacing: CGFloat = 2
}
