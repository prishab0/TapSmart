import SwiftUI

// MARK: - NotificationContext
// Carries the store/card info from a notification tap into CardsView.
// Passed as an EnvironmentObject so any view can observe it.

final class NotificationContext: ObservableObject {
    @Published var storeName: String = ""
    @Published var mcc:       String = ""
    @Published var bestCard:  String = ""
    @Published var cashback:  String = ""

    var hasContext: Bool { !storeName.isEmpty }

    func apply(from url: URL) {
        guard url.host == "cards",
              let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = comps.queryItems else { return }
        storeName = items.first(where: { $0.name == "store"    })?.value ?? ""
        mcc       = items.first(where: { $0.name == "mcc"      })?.value ?? ""
        bestCard  = items.first(where: { $0.name == "card"     })?.value ?? ""
        cashback  = items.first(where: { $0.name == "cashback" })?.value ?? ""
    }

    func clear() {
        storeName = ""; mcc = ""; bestCard = ""; cashback = ""
    }
}

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var locationManager:     LocationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @StateObject private var notifContext       = NotificationContext()

    @State private var selectedTab    = 0
    @State private var showOnboarding = !UserDefaultsStore.hasSeenOnboarding
    @State private var showSettings   = false

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color(hex: "0D1B2A"))
        appearance.stackedLayoutAppearance.normal.iconColor = .white
        appearance.stackedLayoutAppearance.normal.titleTextAttributes =
            [.foregroundColor: UIColor.white]
        UITabBar.appearance().standardAppearance   = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        ZStack {
            Color(hex: "0D1B2A").ignoresSafeArea()

            if showOnboarding {
                OnboardingView(showOnboarding: $showOnboarding)
                    .transition(.opacity)
            } else {
                TabView(selection: $selectedTab) {

                    // ── Savings ───────────────────────────────────────────
                    NavigationStack {
                        SavingsViewWrapper()
                            .navigationTitle("Savings")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbarColorScheme(.dark, for: .navigationBar)
                            .toolbarBackground(Color(hex: "0D1B2A"), for: .navigationBar)
                            .toolbarBackground(.visible, for: .navigationBar)
                    }
                    .tabItem {
                        Image(systemName: "dollarsign.circle.fill")
                        Text("Savings")
                    }
                    .tag(0)

                    // ── Cards ─────────────────────────────────────────────
                    CardsView()
                        .environmentObject(locationManager)
                        .environmentObject(subscriptionManager)
                        .environmentObject(notifContext)      // ← inject context
                        .tabItem {
                            Image(systemName: "creditcard.fill")
                            Text("Cards")
                        }
                        .tag(1)

                    // ── For You ───────────────────────────────────────────
                    NavigationStack {
                        RecommendView()
                            .navigationTitle("Recommendations")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbarColorScheme(.dark, for: .navigationBar)
                            .toolbarBackground(Color(hex: "0D1B2A"), for: .navigationBar)
                            .toolbarBackground(.visible, for: .navigationBar)
                    }
                    .tabItem {
                        Image(systemName: "lightbulb.fill")
                        Text("For You")
                    }
                    .tag(2)

                    // ── Alerts ────────────────────────────────────────────
                    AlertsView()
                        .tabItem {
                            Image(systemName: "bell.fill")
                            Text("Alerts")
                        }
                        .tag(3)

                    // ── Demo ──────────────────────────────────────────────
                    LockScreenView()
                        .environmentObject(locationManager)
                        .tabItem {
                            Image(systemName: "bolt.fill")
                            Text("Live")
                        }
                        .tag(4)
                }
                .accentColor(Color(hex: "14B8A6"))
                .transition(.opacity)
                .onOpenURL { url in
                    guard url.scheme == "tapsmart" else { return }
                    switch url.host {
                    case "savings":   selectedTab = 0
                    case "cards":
                        // Parse notification context BEFORE switching tab
                        // so CardsView gets it in onAppear / onChange
                        notifContext.apply(from: url)
                        selectedTab = 1
                    case "recommend": selectedTab = 2
                    case "alerts":    selectedTab = 3
                    case "demo":      selectedTab = 4
                    default:          selectedTab = 0
                    }
                }
                .sheet(isPresented: $showSettings) {
                    NavigationStack {
                        SettingsView()
                            .environmentObject(subscriptionManager)
                            .toolbarColorScheme(.dark, for: .navigationBar)
                            .toolbarBackground(Color(hex: "0D1B2A"), for: .navigationBar)
                            .toolbarBackground(.visible, for: .navigationBar)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Done") { showSettings = false }
                                        .foregroundColor(Color(hex: "14B8A6"))
                                }
                            }
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showOnboarding)
    }
}

// MARK: - SavingsViewWrapper

private struct SavingsViewWrapper: View {
    @State private var showLogger   = false
    @State private var showShare    = false
    @State private var showSettings = false
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    var body: some View {
        SavingsView(showLogger: $showLogger, showShare: $showShare)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showShare = true } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Color(hex: "14B8A6"))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        NavigationLink(destination: SpendingInsightsView()) {
                            Image(systemName: "chart.pie.fill")
                                .foregroundColor(Color(hex: "14B8A6"))
                                .font(.system(size: 18))
                        }
                        Button { showLogger = true } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color(hex: "14B8A6"))
                                .font(.system(size: 18))
                        }
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(Color(hex: "14B8A6"))
                                .font(.system(size: 18))
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView()
                        .environmentObject(subscriptionManager)
                        .toolbarColorScheme(.dark, for: .navigationBar)
                        .toolbarBackground(Color(hex: "0D1B2A"), for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") { showSettings = false }
                                    .foregroundColor(Color(hex: "14B8A6"))
                            }
                        }
                }
            }
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationManager())
        .environmentObject(SubscriptionManager.shared)
}
