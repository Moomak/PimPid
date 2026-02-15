import SwiftUI

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
            icon: "keyboard.fill",
            title: "พิมพ์ผิดภาษา?",
            description: "เลือกข้อความที่พิมพ์ผิดภาษา แล้วกด shortcut ⌘⇧L เพื่อแปลงทันที",
            color: .purple
        ),
        OnboardingStep(
            icon: "bolt.fill",
            title: "Auto-Correct",
            description: "เปิดใช้ auto-correct เพื่อให้ PimPid แก้ไขอัตโนมัติขณะพิมพ์ โดยไม่ต้องเลือกข้อความ",
            color: .orange
        ),
        OnboardingStep(
            icon: "lock.shield.fill",
            title: "ต้องการสิทธิ์ Accessibility",
            description: "PimPid ต้องการสิทธิ์เพื่อตรวจจับ keyboard shortcut และทำงานได้อย่างถูกต้อง",
            color: .green
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentStep ? steps[index].color : Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
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
                    Spacer()
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
                            KeyboardShortcutManager.openAccessibilitySettings()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)

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
