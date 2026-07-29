import SwiftUI

@main
struct KilnfolkApp: App {
    @StateObject private var store = FolkStore()
    @StateObject private var journey = JourneyStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if !store.onboardingSeen {
                    OnboardingView {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            store.markOnboardingSeen()
                        }
                    }
                    .preferredColorScheme(.light)
                } else {
                    RootView()
                        .environmentObject(store)
                        .environmentObject(journey)
                        .preferredColorScheme(.light)
                }
            }
        }
    }
}
