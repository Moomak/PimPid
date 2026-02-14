import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: PimPidKeys.enabled) }
    }

    init() {
        if UserDefaults.standard.object(forKey: PimPidKeys.enabled) == nil {
            UserDefaults.standard.set(true, forKey: PimPidKeys.enabled)
        }
        self.isEnabled = UserDefaults.standard.bool(forKey: PimPidKeys.enabled)
    }
}
