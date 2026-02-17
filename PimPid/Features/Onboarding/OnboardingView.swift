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
            title: "ยินดีต้อนรับสู่ PimPid",
            description: "แอปที่ช่วยแปลงข้อความไทย ⇄ อังกฤษ ตามตำแหน่งปุ่มคีย์บอร์ด",
            color: .blue
        ),
        OnboardingStep(
            icon: "command",
            title: "Shortcut ⌘⇧L",
            description: "เลือกข้อความที่พิมพ์ผิดภาษาแล้วกด ⌘⇧L เพื่อแปลงทันที (เปลี่ยน shortcut ได้ใน Settings)",
            color: .indigo
        ),
        OnboardingStep(
            icon: "bolt.fill",
            title: "Auto-Correct",
            description: "เปิดใช้ Auto-Correct เพื่อให้ PimPid แก้ไขอัตโนมัติขณะพิมพ์เมื่อตรวจพบการพิมพ์ผิดภาษา",
            color: .orange
        ),
        OnboardingStep(
            icon: "lock.shield.fill",
            title: "ให้สิทธิ์ Accessibility",
            description: "PimPid ต้องการสิทธิ์ Accessibility เพื่อให้ Auto-Correct ทำงานได้",
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
                    Button("ย้อนกลับ") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("ข้าม") {
                        finishOnboarding()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if currentStep < steps.count - 1 {
                    Button("ถัดไป") {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(steps[currentStep].color)
                } else {
                    VStack(spacing: 8) {
                        Button("เปิด System Settings") {
                            UserDefaults.standard.set(true, forKey: PimPidKeys.onboardingDidOpenAccessibilitySettings)
                            AccessibilityHelper.openAccessibilitySettings()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)

                        if UserDefaults.standard.bool(forKey: PimPidKeys.onboardingDidOpenAccessibilitySettings) {
                            Text("ถ้าให้สิทธิ์แล้ว ให้กลับมาแล้วกด เสร็จสิ้น")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Button("เปิดการตั้งค่า PimPid") {
                            NSApplication.shared.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                        }
                        .buttonStyle(.bordered)

                        Button("เสร็จสิ้น") {
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
