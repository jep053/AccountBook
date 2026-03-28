import SwiftUI

@main
struct AccountBookApp: App {
    @StateObject private var languageManager = LanguageManager.shared
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .environmentObject(languageManager)
                    .id(languageManager.currentLanguage)
            } else {
                OnboardingView()
                    .environmentObject(languageManager)
                    .id(languageManager.currentLanguage)
            }
        }
    }
}
