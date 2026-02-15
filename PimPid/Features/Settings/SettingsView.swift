import SwiftUI

/// Main settings view - now uses modern navigation sidebar layout
struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    private var colorScheme: ColorScheme? {
        switch appState.appearanceTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        SettingsNavigationView()
        .preferredColorScheme(colorScheme)
    }
}
