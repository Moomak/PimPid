import SwiftUI
import AppKit

/// Onboarding view shown on first launch
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    @Environment(\.dismiss) private var dismiss

    private let steps: [OnboardingStep] = [
        OnboardingStep(
            icon: "hand.wave.fill",
            title: String(localized: "onboarding.welcome.title", bundle: .module),
            description: String(localized: "onboarding.welcome.desc", bundle: .module),
            color: .blue
        ),
        OnboardingStep(
            icon: "command",
            title: String(localized: "onboarding.shortcut.title", bundle: .module),
            description: String(localized: "onboarding.shortcut.desc", bundle: .module),
            color: .indigo
        ),
        OnboardingStep(
            icon: "bolt.fill",
            title: String(localized: "onboarding.autocorrect.title", bundle: .module),
            description: String(localized: "onboarding.autocorrect.desc", bundle: .module),
            color: .orange
        ),
        OnboardingStep(
            icon: "lock.shield.fill",
            title: String(localized: "onboarding.accessibility.title", bundle: .module),
            description: String(localized: "onboarding.accessibility.desc", bundle: .module),
            color: .green
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator + step number
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Capsule()
                            .fill(index <= currentStep ? steps[index].color : Color.gray.opacity(0.3))
                            .frame(height: 4)
                            .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                }
                Text("\(currentStep + 1) / \(steps.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 40)
            .padding(.top, 30)

            // Content
            TabView(selection: $currentStep) {
                ForEach(0..<steps.count, id: \.self) { index in
                    OnboardingStepView(step: steps[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.automatic)
            .animation(.easeInOut(duration: 0.3), value: currentStep)

            // Navigation buttons
            HStack(spacing: 16) {
                if currentStep > 0 {
                    Button(String(localized: "onboarding.back", bundle: .module)) {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button(String(localized: "onboarding.skip", bundle: .module)) {
                        finishOnboarding()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if currentStep < steps.count - 1 {
                    Button(String(localized: "onboarding.next", bundle: .module)) {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(steps[currentStep].color)
                } else {
                    VStack(spacing: 8) {
                        Button(String(localized: "onboarding.open_system_settings", bundle: .module)) {
                            UserDefaults.standard.set(true, forKey: PimPidKeys.onboardingDidOpenAccessibilitySettings)
                            AccessibilityHelper.openAccessibilitySettings()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)

                        if UserDefaults.standard.bool(forKey: PimPidKeys.onboardingDidOpenAccessibilitySettings) {
                            Text(String(localized: "onboarding.granted_hint", bundle: .module))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Button(String(localized: "onboarding.open_pimpid_settings", bundle: .module)) {
                            NSApplication.shared.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                        }
                        .buttonStyle(.bordered)

                        Button(String(localized: "onboarding.done", bundle: .module)) {
                            finishOnboarding()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
        .frame(width: 500, height: 450)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private func finishOnboarding() {
        appState.hasCompletedOnboarding = true
        dismiss()
    }
}

// MARK: - OnboardingStep

struct OnboardingStep {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - OnboardingStepView

struct OnboardingStepView: View {
    let step: OnboardingStep

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [step.color.opacity(0.3), step.color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: step.icon)
                    .font(.system(size: 50, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [step.color, step.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Title
            Text(step.title)
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)

            // Description
            Text(step.description)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
