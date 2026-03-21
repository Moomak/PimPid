import SwiftUI
import AppKit

/// Onboarding view shown on first launch
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    @Environment(\.dismiss) private var dismiss

    @State private var isAccessibilityGranted = AccessibilityHelper.isAccessibilityTrusted
    private let permissionTimer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    private var steps: [OnboardingStep] {[
        OnboardingStep(
            icon: "hand.wave.fill",
            title: String(localized: "onboarding.welcome.title", bundle: appState.localizedBundle),
            description: String(localized: "onboarding.welcome.desc", bundle: appState.localizedBundle),
            color: .blue
        ),
        OnboardingStep(
            icon: "command",
            title: String(localized: "onboarding.shortcut.title", bundle: appState.localizedBundle),
            description: String(localized: "onboarding.shortcut.desc", bundle: appState.localizedBundle),
            color: .indigo
        ),
        OnboardingStep(
            icon: "bolt.fill",
            title: String(localized: "onboarding.autocorrect.title", bundle: appState.localizedBundle),
            description: String(localized: "onboarding.autocorrect.desc", bundle: appState.localizedBundle),
            color: .orange
        ),
        OnboardingStep(
            icon: "lock.shield.fill",
            title: String(localized: "onboarding.accessibility.title", bundle: appState.localizedBundle),
            description: String(localized: "onboarding.accessibility.desc", bundle: appState.localizedBundle),
            color: .green
        )
    ]}

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
                            .accessibilityHidden(true)
                    }
                }
                Text("\(currentStep + 1) / \(steps.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 40)
            .padding(.top, 30)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Step \(currentStep + 1) of \(steps.count)")
            .accessibilityValue(steps[currentStep].title)

            // Content
            TabView(selection: $currentStep) {
                ForEach(0..<steps.count, id: \.self) { index in
                    if index == steps.count - 1 {
                        // Special accessibility step with detailed instructions
                        AccessibilityStepView(
                            step: steps[index],
                            isGranted: isAccessibilityGranted,
                            localizedBundle: appState.localizedBundle
                        )
                        .tag(index)
                    } else {
                        OnboardingStepView(step: steps[index])
                            .tag(index)
                    }
                }
            }
            .tabViewStyle(.automatic)
            .animation(.easeInOut(duration: 0.3), value: currentStep)

            // Navigation buttons
            HStack(spacing: 16) {
                if currentStep > 0 {
                    Button(String(localized: "onboarding.back", bundle: appState.localizedBundle)) {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button(String(localized: "onboarding.skip", bundle: appState.localizedBundle)) {
                        finishOnboarding()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if currentStep < steps.count - 1 {
                    Button(String(localized: "onboarding.next", bundle: appState.localizedBundle)) {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(steps[currentStep].color)
                } else {
                    HStack(spacing: 12) {
                        if isAccessibilityGranted {
                            Button(String(localized: "onboarding.done", bundle: appState.localizedBundle)) {
                                finishOnboarding()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        } else {
                            Button {
                                UserDefaults.standard.set(true, forKey: PimPidKeys.onboardingDidOpenAccessibilitySettings)
                                AccessibilityHelper.openAccessibilitySettings()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "gear")
                                        .font(.system(size: 12))
                                    Text(String(localized: "onboarding.open_accessibility", bundle: appState.localizedBundle))
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)

                            Button(String(localized: "onboarding.skip", bundle: appState.localizedBundle)) {
                                finishOnboarding()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
        .frame(width: 520, height: 500)
        .background(Color(NSColor.controlBackgroundColor))
        .onReceive(permissionTimer) { _ in
            // Skip polling once already granted (avoid unnecessary AX system calls)
            guard !isAccessibilityGranted else { return }
            isAccessibilityGranted = AccessibilityHelper.isAccessibilityTrusted
        }
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

// MARK: - AccessibilityStepView

/// Dedicated view for the Accessibility permission step with step-by-step instructions
struct AccessibilityStepView: View {
    let step: OnboardingStep
    let isGranted: Bool
    let localizedBundle: Bundle

    var body: some View {
        VStack(spacing: 20) {
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
                    .frame(width: 90, height: 90)

                Image(systemName: isGranted ? "checkmark.shield.fill" : step.icon)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [isGranted ? .green : step.color, (isGranted ? .green : step.color).opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Title
            Text(step.title)
                .font(.system(size: 22, weight: .bold))
                .multilineTextAlignment(.center)

            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(isGranted ? Color.green : Color.orange)
                    .frame(width: 10, height: 10)
                    .accessibilityHidden(true)
                Text(isGranted
                     ? String(localized: "onboarding.a11y.status.granted", bundle: localizedBundle)
                     : String(localized: "onboarding.a11y.status.not_granted", bundle: localizedBundle))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isGranted ? .green : .orange)
            }
            .accessibilityElement(children: .combine)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isGranted ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
            )

            if isGranted {
                Text(String(localized: "onboarding.a11y.all_set", bundle: localizedBundle))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            } else {
                // Step-by-step instructions
                VStack(alignment: .leading, spacing: 10) {
                    InstructionRow(
                        number: "1",
                        text: String(localized: "onboarding.a11y.step1", bundle: localizedBundle),
                        color: step.color
                    )
                    InstructionRow(
                        number: "2",
                        text: String(localized: "onboarding.a11y.step2", bundle: localizedBundle),
                        color: step.color
                    )
                    InstructionRow(
                        number: "3",
                        text: String(localized: "onboarding.a11y.step3", bundle: localizedBundle),
                        color: step.color
                    )
                }
                .padding(.horizontal, 50)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A numbered instruction row
struct InstructionRow: View {
    let number: String
    let text: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(color))

            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
