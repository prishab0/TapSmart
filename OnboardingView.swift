import SwiftUI

// MARK: - OnboardingPage model

private struct OnboardingPage {
    let icon: String
    let accentColor: String
    let headline: String
    let subheadline: String
    let body: String
    let actionLabel: String
}

private let pages: [OnboardingPage] = [
    OnboardingPage(
        icon: "📍",
        accentColor: "14B8A6",
        headline: "The right card,\nright when you need it.",
        subheadline: "Location-smart recommendations",
        body: "Manju watches where you are and tells you which card in your wallet earns the most cash back at that exact store — before you tap.",
        actionLabel: "Next"
    ),
    OnboardingPage(
        icon: "💳",
        accentColor: "F59E0B",
        headline: "Every card.\nEvery category.",
        subheadline: "Your whole wallet, optimised",
        body: "Add the cards you already own. Manju knows every reward rate for every card and ranks them instantly — groceries, dining, gas, travel, and more.",
        actionLabel: "Next"
    ),
    OnboardingPage(
        icon: "🚀",
        accentColor: "22C55E",
        headline: "Watch your\ncash back stack up.",
        subheadline: "Track, streak, and save more",
        body: "Every time you use the best card Manju builds your savings total and keeps your streak alive. See exactly how much smarter spending has earned you.",
        actionLabel: "Let's go"
    ),
]

// MARK: - OnboardingView

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var currentPage = 0
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var textOffset: CGFloat = 30
    @State private var textOpacity: Double = 0
    @State private var cardOffset: CGFloat = 60
    @State private var cardOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.9
    @State private var buttonOpacity: Double = 0
    @State private var particleOpacity: Double = 0

    private var page: OnboardingPage { pages[currentPage] }
    private var isLast: Bool { currentPage == pages.count - 1 }

    var body: some View {
        ZStack {
            // ── Background ────────────────────────────────────────
            Color(hex: "0D1B2A").ignoresSafeArea()

            // Ambient glow behind icon
            Circle()
                .fill(Color(hex: page.accentColor).opacity(0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .offset(y: -80)
                .animation(.easeInOut(duration: 0.6), value: currentPage)

            // Subtle grid lines
            GeometryReader { geo in
                Path { path in
                    let spacing: CGFloat = 44
                    var x: CGFloat = 0
                    while x < geo.size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                        x += spacing
                    }
                    var y: CGFloat = 0
                    while y < geo.size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                        y += spacing
                    }
                }
                .stroke(Color.white.opacity(0.03), lineWidth: 0.5)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {

                Spacer()

                // ── Icon ──────────────────────────────────────────
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(Color(hex: page.accentColor).opacity(0.25), lineWidth: 1.5)
                        .frame(width: 140, height: 140)
                        .scaleEffect(iconScale)
                        .opacity(iconOpacity)

                    // Inner fill
                    Circle()
                        .fill(Color(hex: page.accentColor).opacity(0.15))
                        .frame(width: 110, height: 110)
                        .scaleEffect(iconScale)
                        .opacity(iconOpacity)

                    Text(page.icon)
                        .font(.system(size: 52))
                        .scaleEffect(iconScale)
                        .opacity(iconOpacity)
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.65), value: currentPage)

                Spacer().frame(height: 44)

                // ── Text block ────────────────────────────────────
                VStack(spacing: 14) {

                    // Subheadline pill
                    Text(page.subheadline.uppercased())
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(Color(hex: page.accentColor))
                        .tracking(2)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color(hex: page.accentColor).opacity(0.12))
                        .cornerRadius(20)
                        .offset(y: textOffset)
                        .opacity(textOpacity)

                    // Headline
                    Text(page.headline)
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .offset(y: textOffset)
                        .opacity(textOpacity)
                        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.05), value: currentPage)

                    // Body
                    Text(page.body)
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .padding(.horizontal, 32)
                        .offset(y: textOffset)
                        .opacity(textOpacity)
                        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1), value: currentPage)
                }

                Spacer()

                // ── Feature card ──────────────────────────────────
                FeatureCard(page: page)
                    .offset(y: cardOffset)
                    .opacity(cardOpacity)
                    .padding(.horizontal, 24)

                Spacer().frame(height: 36)

                // ── Page dots ─────────────────────────────────────
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage
                                  ? Color(hex: page.accentColor)
                                  : Color.white.opacity(0.2))
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.4), value: currentPage)
                    }
                }
                .opacity(buttonOpacity)

                Spacer().frame(height: 28)

                // ── CTA button ────────────────────────────────────
                Button {
                    advance()
                } label: {
                    HStack(spacing: 10) {
                        Text(page.actionLabel)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Image(systemName: isLast ? "checkmark" : "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color(hex: page.accentColor))
                    .cornerRadius(18)
                    .shadow(color: Color(hex: page.accentColor).opacity(0.4),
                            radius: 16, x: 0, y: 8)
                }
                .padding(.horizontal, 24)
                .scaleEffect(buttonScale)
                .opacity(buttonOpacity)

                // Skip (not on last page)
                if !isLast {
                    Button("Skip") { finish() }
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.35))
                        .padding(.top, 16)
                        .opacity(buttonOpacity)
                }

                Spacer().frame(height: 48)
            }
        }
        .onAppear { animateIn() }
    }

    // MARK: - Helpers

    private func advance() {
        if isLast {
            finish()
        } else {
            animateOut {
                currentPage += 1
                animateIn()
            }
        }
    }

    private func finish() {
        UserDefaultsStore.hasSeenOnboarding = true
        // Re-apply nav bar appearance — onboarding transition can reset it
        TapSmartApp.applyNavBarAppearance()
        withAnimation(.easeInOut(duration: 0.35)) {
            showOnboarding = false
        }
    }

    private func animateIn() {
        iconScale   = 0.5;  iconOpacity   = 0
        textOffset  = 30;   textOpacity   = 0
        cardOffset  = 60;   cardOpacity   = 0
        buttonScale = 0.9;  buttonOpacity = 0

        withAnimation(.spring(response: 0.55, dampingFraction: 0.68)) {
            iconScale = 1; iconOpacity = 1
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1)) {
            textOffset = 0; textOpacity = 1
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.2)) {
            cardOffset = 0; cardOpacity = 1
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7).delay(0.28)) {
            buttonScale = 1; buttonOpacity = 1
        }
    }

    private func animateOut(completion: @escaping () -> Void) {
        withAnimation(.easeIn(duration: 0.2)) {
            iconOpacity = 0; textOpacity = 0
            cardOpacity = 0; buttonOpacity = 0
            textOffset = -20; cardOffset = -30
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            completion()
        }
    }
}

// MARK: - FeatureCard

private struct FeatureCard: View {
    let page: OnboardingPage

    private var features: [(String, String)] {
        switch page.icon {
        case "📍": return [
            ("bell.fill",         "Notified when you arrive"),
            ("map.fill",          "Works at 20+ store types"),
            ("lock.shield.fill",  "Location never stored"),
        ]
        case "💳": return [
            ("creditcard.fill",   "50+ cards supported"),
            ("star.fill",         "Rates updated regularly"),
            ("slider.horizontal.3", "Filter by category"),
        ]
        default: return [
            ("flame.fill",        "Daily & weekly streaks"),
            ("chart.line.uptrend.xyaxis", "Track savings over time"),
            ("gift.fill",         "Card of the Month picks"),
        ]
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(features.enumerated()), id: \.offset) { idx, feat in
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: page.accentColor).opacity(0.15))
                            .frame(width: 38, height: 38)
                        Image(systemName: feat.0)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: page.accentColor))
                    }
                    Text(feat.1)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                    Spacer()
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: page.accentColor).opacity(0.7))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

                if idx < features.count - 1 {
                    Divider()
                        .background(Color.white.opacity(0.07))
                        .padding(.leading, 72)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: page.accentColor).opacity(0.2), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.3), value: page.icon)
    }
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
}
