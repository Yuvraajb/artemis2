//
//  OnboardingView.swift
//  artemis2
//
//  Cinematic prologue — a multi-stage cold open that builds from the void
//  of space into the full mission experience.
//
//  Sequence:
//  1. Darkness + tap-to-reveal stars mini-game + heartbeat haptics
//  2. Dark bass fades in as stars fill the sky
//  3. "1972" → "2026" year reveals with Neil Armstrong's voice
//  4. Story text → "Until now." → camera pan begins
//  5. Mission details → "ARTEMIS II"
//  6. Hold-to-ignite → white flash → crossfade to zen ambient → app
//

import SwiftUI

// MARK: - Prologue Stages

private enum PrologueStage: Int, Comparable {
    case darkness = 0      // Black + tap-to-reveal stars + heartbeat
    case year1972 = 1      // "1972" large
    case year2026 = 2      // "2026" large + Neil starts
    case storyText = 3     // Descriptive text about the mission
    case untilNow = 4      // "Until now." + camera starts + black dissolves
    case cameraPan = 5     // Pan with mission details + "ARTEMIS II"
    case ignite = 6        // Hold-to-ignite

    static func < (lhs: PrologueStage, rhs: PrologueStage) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Star Field

private struct StarField: View {
    let revealedCount: Int
    let tapPositions: [CGPoint]
    private let totalStars = 80
    private let seed: UInt64 = 42

    var body: some View {
        Canvas { context, size in
            // Tap-spawned stars (brighter, slightly larger)
            for pos in tapPositions {
                let starSize: CGFloat = 2.5
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: pos.x - starSize / 2, y: pos.y - starSize / 2,
                        width: starSize, height: starSize
                    )),
                    with: .color(.white.opacity(0.9))
                )
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: pos.x - 4, y: pos.y - 4, width: 8, height: 8
                    )),
                    with: .color(.white.opacity(0.08))
                )
            }

            // Ambient background stars
            var rng = SeededRNG(seed: seed)
            for i in 0..<totalStars {
                let x = CGFloat.random(in: 0..<size.width, using: &rng)
                let y = CGFloat.random(in: 0..<size.height, using: &rng)
                let starSize = CGFloat.random(in: 0.5...2.0, using: &rng)
                let brightness = CGFloat.random(in: 0.3...1.0, using: &rng)
                let opacity = i < revealedCount ? brightness : 0
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: starSize, height: starSize)),
                    with: .color(.white.opacity(opacity))
                )
            }
        }
        .ignoresSafeArea()
    }
}

private struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}

// MARK: - View

struct OnboardingCameraPanView: View {
    @Bindable var viewModel: MissionViewModel
    @Environment(AccessibilitySettings.self) private var a11y
    let onComplete: () -> Void

    // Stage
    @State private var stage: PrologueStage = .darkness

    // Stars — tap mini-game
    @State private var revealedStars: Int = 0
    @State private var starTimer: Timer?
    @State private var tapStars: [CGPoint] = []
    @State private var showTapHint = false

    // Text
    @State private var show1972 = false
    @State private var show2026 = false
    @State private var showStoryLine1 = false
    @State private var showStoryLine2 = false
    @State private var showUntilNow = false
    @State private var showMissionLine = false
    @State private var showArtemisTitle = false

    // Camera
    @State private var cameraProgress: Double = 0
    @State private var cameraTimer: Timer?
    private let cameraDuration: Double = 14.0
    private let fps: TimeInterval = 1.0 / 30.0

    // Ignite
    @State private var holdProgress: CGFloat = 0
    @State private var isHolding = false
    @State private var holdTimer: Timer?
    @State private var showIgnitePrompt = false
    @State private var ignited = false
    @State private var flashOpacity: Double = 0

    // Skip
    @State private var showSkip = false

    var body: some View {
        ZStack {
            OrbitSceneView(viewModel: viewModel)
                .ignoresSafeArea()

            Color.black
                .ignoresSafeArea()
                .opacity(blackOverlayOpacity)
                .allowsHitTesting(false)

            // Stars (tap-interactive during darkness stage)
            if stage.rawValue <= PrologueStage.untilNow.rawValue {
                StarField(revealedCount: revealedStars, tapPositions: tapStars)
                    .opacity(blackOverlayOpacity)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                if stage == .darkness {
                                    spawnTapStar(at: value.location)
                                }
                            }
                    )
            }

            // Tap hint
            if showTapHint && stage == .darkness {
                VStack {
                    Spacer()
                    Text("tap to explore the void")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                        .tracking(2)
                        .padding(.bottom, 60)
                }
                .transition(.opacity)
                .allowsHitTesting(false)
            }

            textLayer

            if stage == .ignite && !ignited {
                igniteLayer
                    .transition(.opacity)
            }

            Color.white
                .ignoresSafeArea()
                .opacity(flashOpacity)
                .allowsHitTesting(false)

            // Skip button
            VStack {
                HStack {
                    Spacer()
                    if showSkip && !ignited {
                        Button("Skip") { skipToEnd() }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .transition(.opacity)
                    }
                }
                Spacer()
            }
        }
        .onAppear {
            viewModel.isOnboarding = true
            if a11y.reduceMotion {
                skipToEnd()
            } else {
                beginPrologue()
            }
        }
        .onDisappear {
            starTimer?.invalidate()
            cameraTimer?.invalidate()
            holdTimer?.invalidate()
            HapticManager.shared.stopHeartbeat()
        }
    }

    // MARK: - Tap Star Mini-Game

    private func spawnTapStar(at point: CGPoint) {
        tapStars.append(point)
        HapticManager.shared.prologuePulse(intensity: 0.15)
    }

    // MARK: - Black Overlay

    private var blackOverlayOpacity: Double {
        switch stage {
        case .darkness, .year1972, .year2026, .storyText:
            return 1.0
        case .untilNow:
            return max(0, 1.0 - cameraProgress * 3.5)
        case .cameraPan, .ignite:
            return 0
        }
    }

    // MARK: - Text Layer

    private var textLayer: some View {
        ZStack {
            yearLayer
            storyLayer
            panDetailLayer
        }
        .animation(.easeInOut(duration: 0.8), value: show1972)
        .animation(.easeInOut(duration: 0.8), value: show2026)
        .animation(.easeInOut(duration: 0.8), value: showStoryLine1)
        .animation(.easeInOut(duration: 0.8), value: showStoryLine2)
        .animation(.easeInOut(duration: 0.6), value: showUntilNow)
        .animation(.easeInOut(duration: 0.8), value: showMissionLine)
        .animation(.easeInOut(duration: 0.8), value: showArtemisTitle)
    }

    private var yearLayer: some View {
        VStack {
            Spacer()
            if show1972 && stage == .year1972 {
                VStack(spacing: 8) {
                    Text("1972")
                        .font(.system(size: 64, weight: .ultraLight, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.9))
                        .tracking(8)
                    Text("The last time humans walked on the Moon")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .tracking(1)
                }
                .transition(.opacity)
            }
            if show2026 && stage == .year2026 {
                VStack(spacing: 8) {
                    Text("2026")
                        .font(.system(size: 64, weight: .ultraLight, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.9))
                        .tracking(8)
                    Text("Humanity returns")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .tracking(1)
                }
                .transition(.opacity)
            }
            Spacer()
        }
    }

    private var storyLayer: some View {
        VStack(spacing: 20) {
            Spacer()
            if showStoryLine1 && (stage == .storyText || stage == .untilNow) {
                Text("For 54 years, no one has traveled\nbeyond low Earth orbit.")
                    .prologueText()
                    .transition(.opacity)
            }
            if showStoryLine2 && (stage == .storyText || stage == .untilNow) {
                Text("Four astronauts aboard NASA's Orion\nspacecraft are about to change that —\nflying 400,000 km to the Moon and back.")
                    .prologueText(size: 14)
                    .transition(.opacity)
            }
            if showUntilNow && stage == .untilNow {
                Text("This is their journey.")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .tracking(3)
                    .transition(.opacity)
                    .padding(.top, 12)
            }
            Spacer()
        }
    }

    private var panDetailLayer: some View {
        VStack {
            Spacer()
            if stage == .cameraPan && !ignited {
                VStack(spacing: 14) {
                    if showMissionLine {
                        Text("10 days. 1.3 million km.\nThe farthest any human has ever traveled.")
                            .prologueText(size: 14)
                            .transition(.opacity)
                    }
                    if showArtemisTitle {
                        VStack(spacing: 6) {
                            Text("ARTEMIS II")
                                .font(.system(size: 22, weight: .heavy, design: .default))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, .cyan.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .tracking(6)
                            Text("JOURNEY TO THE MOON")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.4))
                                .tracking(3)
                        }
                        .transition(.opacity)
                    }
                }
                .padding(.bottom, 100)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: stage)
    }

    // MARK: - Ignite Layer

    private var igniteLayer: some View {
        VStack(spacing: 20) {
            Spacer()

            if showIgnitePrompt {
                Text("HOLD TO IGNITE")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5 + holdProgress * 0.5))
                    .tracking(4)
                    .transition(.opacity)

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 4)
                        .frame(width: 90, height: 90)

                    Circle()
                        .trim(from: 0, to: holdProgress)
                        .stroke(
                            LinearGradient(
                                colors: [.cyan, .white],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.cyan.opacity(0.1 + holdProgress * 0.4),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 45
                            )
                        )
                        .frame(width: 90, height: 90)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            Color.white.opacity(0.4 + holdProgress * 0.6)
                        )
                        .scaleEffect(1.0 + holdProgress * 0.2)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isHolding { beginHold() }
                        }
                        .onEnded { _ in
                            cancelHold()
                        }
                )
                .animation(.easeOut(duration: 0.15), value: holdProgress)

                Text("engines ready")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
            }

            Spacer()
                .frame(height: 80)
        }
        .animation(.easeInOut(duration: 0.8), value: showIgnitePrompt)
    }

    // MARK: - Prologue Sequencer

    private func beginPrologue() {
        // Phase 1: Heartbeat in the void + tap mini-game (0-7s)
        HapticManager.shared.startHeartbeat()
        startStarReveal()

        withAnimation(.easeIn(duration: 0.6).delay(1.5)) { showTapHint = true }
        withAnimation(.easeIn(duration: 0.4).delay(3.0)) { showSkip = true }

        // Phase 2: Dark bass fades in (4s)
        schedule(delay: 4.0) {
            MissionAudioManager.shared.startIntro(fadeDuration: 2.5, targetVolume: 0.7)
        }

        // Fade out tap hint
        schedule(delay: 6.0) {
            withAnimation(.easeOut(duration: 0.5)) { showTapHint = false }
        }

        // Phase 3: "1972" + Neil's voice begins (7s)
        schedule(delay: 7.0) {
            stage = .year1972
            show1972 = true
            HapticManager.shared.prologueThud()
            MissionAudioManager.shared.startNeil(fadeDuration: 1.5, targetVolume: 0.85)
        }

        // Phase 4: "2026" (11s)
        schedule(delay: 11.0) {
            show1972 = false
        }
        schedule(delay: 11.8) {
            stage = .year2026
            show2026 = true
            HapticManager.shared.prologueThud()
        }

        // Phase 5: Story text (16s)
        schedule(delay: 16.0) {
            show2026 = false
        }
        schedule(delay: 17.0) {
            stage = .storyText
            showStoryLine1 = true
            HapticManager.shared.prologuePulse(intensity: 0.3)
        }
        schedule(delay: 20.5) {
            showStoryLine2 = true
            HapticManager.shared.prologuePulse(intensity: 0.35)
        }

        // Phase 6: "This is their journey." + camera starts (25s)
        schedule(delay: 25.0) {
            stage = .untilNow
            showUntilNow = true
            HapticManager.shared.stopHeartbeat()
            HapticManager.shared.prologuePulse(intensity: 0.5)
            starTimer?.invalidate()
            startCameraPan()
            MissionAudioManager.shared.fadeOutNeil(duration: 3.0)
        }

        // Phase 7: Clear story text, show pan details
        schedule(delay: 28.0) {
            showStoryLine1 = false
            showStoryLine2 = false
            showUntilNow = false
        }

        schedule(delay: 29.0) {
            stage = .cameraPan
            showMissionLine = true
            HapticManager.shared.prologuePulse(intensity: 0.35)
        }

        schedule(delay: 32.0) {
            showArtemisTitle = true
            HapticManager.shared.prologuePulse(intensity: 0.4)
        }
    }

    // MARK: - Star Reveal

    private func startStarReveal() {
        var count = 0
        starTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { t in
            count += 1
            revealedStars = count
            if count >= 80 {
                t.invalidate()
                starTimer = nil
            }
        }
    }

    // MARK: - Camera Pan

    private func startCameraPan() {
        let increment = 1.0 / (cameraDuration / fps)
        cameraTimer = Timer.scheduledTimer(withTimeInterval: fps, repeats: true) { t in
            cameraProgress += increment
            viewModel.onboardingCameraProgress = min(1, cameraProgress)
            if cameraProgress >= 1 {
                t.invalidate()
                cameraTimer = nil
                arriveAtIgnite()
            }
        }
        cameraTimer?.tolerance = 0.02
        RunLoop.main.add(cameraTimer!, forMode: .common)
    }

    private func arriveAtIgnite() {
        viewModel.onboardingCameraProgress = 1
        withAnimation(.easeInOut(duration: 0.5)) {
            showMissionLine = false
            showArtemisTitle = false
        }

        schedule(delay: 0.6) {
            stage = .ignite
            showIgnitePrompt = true
            HapticManager.shared.prologuePulse(intensity: 0.45)
        }
    }

    // MARK: - Hold-to-Ignite

    private func beginHold() {
        isHolding = true
        HapticManager.shared.prologuePulse(intensity: 0.35)
        HapticManager.shared.igniteChargeStart()

        holdTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            guard isHolding else { return }
            holdProgress += 1.0 / (2.5 * 60.0)

            let progress = Float(min(1, holdProgress))
            HapticManager.shared.igniteChargeUpdate(progress: progress)

            if holdProgress >= 1.0 {
                holdTimer?.invalidate()
                holdTimer = nil
                triggerIgnition()
            }
        }
    }

    private func cancelHold() {
        isHolding = false
        holdTimer?.invalidate()
        holdTimer = nil
        withAnimation(.easeOut(duration: 0.3)) {
            holdProgress = 0
        }
        HapticManager.shared.igniteChargeCancel()
    }

    private func triggerIgnition() {
        ignited = true
        isHolding = false

        HapticManager.shared.igniteComplete()
        MissionAudioManager.shared.crossfadeToAmbient(duration: 3.0)

        withAnimation(.easeOut(duration: 0.15)) {
            flashOpacity = 0.8
        }

        schedule(delay: 0.15) {
            withAnimation(.easeIn(duration: 1.2)) {
                flashOpacity = 0
            }
        }

        schedule(delay: 1.5) {
            viewModel.isOnboarding = false
            viewModel.onboardingCameraProgress = 0
            onComplete()
        }
    }

    // MARK: - Skip

    private func skipToEnd() {
        starTimer?.invalidate()
        cameraTimer?.invalidate()
        holdTimer?.invalidate()
        HapticManager.shared.stopHeartbeat()

        MissionAudioManager.shared.stopIntro()
        MissionAudioManager.shared.stopNeil()
        MissionAudioManager.shared.fadeInAmbient(duration: 1.5)

        viewModel.onboardingCameraProgress = 1
        viewModel.isOnboarding = false
        onComplete()
    }

    // MARK: - Utilities

    private func schedule(delay: TimeInterval, action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: action)
    }
}

// MARK: - Text Style

private extension Text {
    func prologueText(size: CGFloat = 17) -> some View {
        self
            .font(.system(size: size, weight: .medium, design: .monospaced))
            .foregroundStyle(.white.opacity(0.85))
            .tracking(1.5)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
    }
}

#Preview {
    OnboardingCameraPanView(viewModel: MissionViewModel(), onComplete: {})
        .environment(AccessibilitySettings())
}
