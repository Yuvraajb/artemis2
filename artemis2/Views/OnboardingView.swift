//
//  OnboardingView.swift
//  artemis2
//
//  Step 1 of onboarding: full-screen camera pan from behind Earth to Moon.
//  When the camera arrives at the Moon a "Start Journey" button fades in.
//  Tapping it triggers the transition into the progressive dashboard reveal.
//

import SwiftUI

struct OnboardingCameraPanView: View {
    @Bindable var viewModel: MissionViewModel
    @Environment(AccessibilitySettings.self) private var a11y
    let onComplete: () -> Void

    @State private var cameraProgress: Double = 0
    @State private var timer: Timer?
    @State private var showSkip = false
    @State private var showStartButton = false

    private let cameraDuration: Double = 10.0
    private let timerInterval: TimeInterval = 1.0 / 30.0

    var body: some View {
        ZStack {
            OrbitSceneView(viewModel: viewModel)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    if showSkip && !showStartButton {
                        Button("Skip") { showJourneyButton() }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .transition(.opacity)
                    }
                }

                Spacer()

                if showStartButton {
                    Button(action: { finish() }) {
                        Text("Start Journey")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 36)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(.white)
                                    .shadow(color: .white.opacity(0.5), radius: 20, y: 0)
                            )
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .padding(.bottom, 80)
                } else {
                    Text("Artemis II — Journey to the Moon")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            viewModel.isOnboarding = true
            startAnimation()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private func startAnimation() {
        if a11y.reduceMotion {
            viewModel.onboardingCameraProgress = 1
            showJourneyButton()
            return
        }
        withAnimation(.easeIn(duration: 0.4).delay(1.0)) { showSkip = true }
        let increment = 1.0 / (cameraDuration / timerInterval)
        timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { t in
            cameraProgress += increment
            viewModel.onboardingCameraProgress = min(1, cameraProgress)
            if cameraProgress >= 1 {
                t.invalidate()
                self.timer = nil
                showJourneyButton()
            }
        }
        timer?.tolerance = 0.02
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func showJourneyButton() {
        timer?.invalidate()
        timer = nil
        viewModel.onboardingCameraProgress = 1
        withAnimation(.easeOut(duration: 0.8)) {
            showStartButton = true
        }
    }

    private func finish() {
        viewModel.isOnboarding = false
        viewModel.onboardingCameraProgress = 0
        onComplete()
    }
}

#Preview {
    OnboardingCameraPanView(viewModel: MissionViewModel(), onComplete: {})
        .environment(AccessibilitySettings())
}
