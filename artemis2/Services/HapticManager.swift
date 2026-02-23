//
//  HapticManager.swift
//  artemis2
//
//  Haptic feedback engine using Core Haptics.
//  Each pattern is designed to match a specific visual moment
//  in the mission — not generic buzzes but physically meaningful feedback.
//

import CoreHaptics
import UIKit

final class HapticManager {
    static let shared = HapticManager()

    private var engine: CHHapticEngine?
    private var continuousPlayer: CHHapticAdvancedPatternPlayer?
    private let supportsHaptics: Bool
    private var isContinuousActive = false

    // MARK: - Setup

    private init() {
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        if supportsHaptics { prepareEngine() }
    }

    private func prepareEngine() {
        do {
            engine = try CHHapticEngine()
            engine?.playsHapticsOnly = true
            engine?.stoppedHandler = { [weak self] _ in
                self?.restartEngine()
            }
            engine?.resetHandler = { [weak self] in
                self?.restartEngine()
            }
            try engine?.start()
        } catch { }
    }

    private func restartEngine() {
        guard supportsHaptics else { return }
        try? engine?.start()
    }

    private func ensureRunning() {
        guard supportsHaptics else { return }
        try? engine?.start()
    }

    // MARK: - Countdown (T-10 to T-0)
    // Clean single taps that get heavier approaching zero.
    // Matches the visual countdown timer ticking down.

    func countdownTick(secondsRemaining: Int) {
        guard supportsHaptics else { return }
        let normalised = 1.0 - (Float(secondsRemaining) / 10.0) // 0 at T-10, 1 at T-0
        let intensity = 0.25 + normalised * 0.65 // 0.25 → 0.9
        let sharpness: Float = secondsRemaining <= 3 ? 0.7 : 0.4
        playTransient(intensity: intensity, sharpness: sharpness)
    }

    // MARK: - Phase Transitions
    // Called when the mission transitions between phases.

    func phaseTransition(from old: MissionPhase, to new: MissionPhase) {
        guard supportsHaptics else { return }

        switch new {
        case .prelaunch:
            stopContinuous()

        case .launch:
            // Engines ignite — rapid crescendo of taps then continuous rumble
            playIgnitionSequence()

        case .earthOrbit:
            // Engines cut off. Silence = weightlessness.
            stopContinuous()
            playTransient(intensity: 0.3, sharpness: 0.15) // one soft final "clunk"

        case .translunarInjection:
            // Single engine fires — smoother, lighter thrust
            startContinuous(intensity: 0.35, sharpness: 0.15)

        case .translunarCoast:
            // Engine cuts, ICPS separates. Silence again.
            stopContinuous()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                self.playTransient(intensity: 0.5, sharpness: 0.8) // separation clunk
            }

        case .lunarFlyby:
            // The emotional peak — gentle heartbeat pulse
            playLunarHeartbeat()

        case .returnTransit:
            // Gentle acknowledgment, then silence for the coast home
            playTransient(intensity: 0.3, sharpness: 0.3)

        case .reentry:
            // Atmosphere hits — building, chaotic vibration
            startContinuous(intensity: 0.5, sharpness: 0.45)
        }
    }

    // MARK: - Continuous Thrust Feedback
    // Maps directly to current G-force so you feel what the crew feels.

    func startContinuous(intensity: Float, sharpness: Float) {
        guard supportsHaptics, let engine else { return }
        ensureRunning()

        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: 0,
            duration: 300
        )

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            continuousPlayer = try engine.makeAdvancedPlayer(with: pattern)
            try continuousPlayer?.start(atTime: CHHapticTimeImmediate)
            isContinuousActive = true
        } catch { }
    }

    /// Dynamically update continuous intensity based on G-force / phase progress
    func updateContinuousIntensity(gForce: Double, phase: MissionPhase) {
        guard supportsHaptics, isContinuousActive else { return }

        let (intensity, sharpness): (Float, Float) = switch phase {
        case .launch:
            // G-force drives intensity: 1G → soft, 2.5G → strong
            (Float(min(1.0, 0.25 + gForce * 0.22)), Float(min(0.5, 0.1 + gForce * 0.08)))
        case .translunarInjection:
            // Smoother, lighter burn
            (Float(0.3 + gForce * 0.15), Float(0.15))
        case .reentry:
            // G-force drives intensity: more chaotic at higher G
            (Float(min(1.0, 0.3 + gForce * 0.18)), Float(min(0.7, 0.3 + gForce * 0.1)))
        default:
            (0.3, 0.2)
        }

        let iParam = CHHapticDynamicParameter(
            parameterID: .hapticIntensityControl, value: intensity, relativeTime: 0)
        let sParam = CHHapticDynamicParameter(
            parameterID: .hapticSharpnessControl, value: sharpness, relativeTime: 0)
        try? continuousPlayer?.sendParameters([iParam, sParam], atTime: CHHapticTimeImmediate)
    }

    func stopContinuous() {
        guard isContinuousActive else { return }
        try? continuousPlayer?.stop(atTime: CHHapticTimeImmediate)
        continuousPlayer = nil
        isContinuousActive = false
    }

    func pauseContinuous() {
        guard isContinuousActive else { return }
        try? continuousPlayer?.stop(atTime: CHHapticTimeImmediate)
    }

    func resumeContinuous() {
        guard isContinuousActive else { return }
        try? continuousPlayer?.start(atTime: CHHapticTimeImmediate)
    }

    // MARK: - Milestone Haptics
    // Each milestone gets a pattern that matches what's visually happening.

    func milestoneHaptic(name: String) {
        guard supportsHaptics else { return }

        switch name {
        case "Engine Ignition":
            break // Handled by phaseTransition → launch

        case "Max-Q":
            // Peak aerodynamic pressure — sharp spike overlaid on rumble
            playTransient(intensity: 0.9, sharpness: 0.8)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                self.playTransient(intensity: 0.7, sharpness: 0.6)
            }

        case "Booster Separation", "Core Stage Separation", "ICPS Separation":
            // Physical detachment: brief gap in rumble, then sharp clunk
            pauseContinuous()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                self.playTransient(intensity: 0.85, sharpness: 0.9) // the clunk
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.resumeContinuous()
            }

        case "Orbit Insertion":
            // Arrival — two clean taps
            playDoubleTap(intensity: 0.4, sharpness: 0.3)

        case "TLI Burn":
            break // Handled by phaseTransition → TLI

        case "Halfway to Moon":
            playTransient(intensity: 0.35, sharpness: 0.3)

        case "Lunar Closest Approach":
            playLunarHeartbeat()

        case "Farthest from Earth":
            // A single, meaningful, medium tap — a moment of awe
            playTransient(intensity: 0.5, sharpness: 0.2)

        case "Entry Interface":
            break // Handled by phaseTransition → reentry

        case "Skip Maneuver":
            playSkipManeuver()

        case "Splashdown":
            playSplashdown()

        default:
            playTransient(intensity: 0.4, sharpness: 0.3)
        }
    }

    // MARK: - Challenge Haptics

    func challengeSuccess() {
        guard supportsHaptics else { return }
        // Ascending triplet: tap-TAP-TAP! Matches the success checkmark animation.
        playTransient(intensity: 0.3, sharpness: 0.4)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playTransient(intensity: 0.55, sharpness: 0.5)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.playTransient(intensity: 0.85, sharpness: 0.6)
        }
    }

    func challengeCorrection() {
        guard supportsHaptics else { return }
        // Two soft taps — acknowledging but not celebratory
        playTransient(intensity: 0.4, sharpness: 0.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.playTransient(intensity: 0.25, sharpness: 0.3)
        }
    }

    // MARK: - Mission Complete

    func missionComplete() {
        guard supportsHaptics else { return }
        // Celebratory pattern: three ascending beats then a final flourish
        let delays: [(TimeInterval, Float, Float)] = [
            (0.0,  0.3, 0.3),
            (0.12, 0.5, 0.4),
            (0.24, 0.7, 0.5),
            (0.44, 0.9, 0.6),
            (0.52, 0.6, 0.3),
            (0.58, 0.4, 0.2),
        ]
        for (delay, intensity, sharpness) in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.playTransient(intensity: intensity, sharpness: sharpness)
            }
        }
    }

    // MARK: - Special Sequences

    /// Engine ignition: rapid taps that accelerate into continuous rumble
    private func playIgnitionSequence() {
        let taps: [(TimeInterval, Float)] = [
            (0.00, 0.2), (0.06, 0.25), (0.11, 0.3),
            (0.15, 0.4), (0.18, 0.5), (0.20, 0.6),
        ]
        for (delay, intensity) in taps {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.playTransient(intensity: intensity, sharpness: 0.2)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.startContinuous(intensity: 0.55, sharpness: 0.2)
        }
    }

    /// Lunar heartbeat: two close taps, pause, two close taps.
    /// The rhythm of a heartbeat at the emotional peak of the mission.
    private func playLunarHeartbeat() {
        let pattern: [(TimeInterval, Float)] = [
            (0.0, 0.35), (0.12, 0.5),   // lub-dub
            (0.6, 0.35), (0.72, 0.5),   // lub-dub
        ]
        for (delay, intensity) in pattern {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.playTransient(intensity: intensity, sharpness: 0.15)
            }
        }
    }

    /// Skip reentry: intensity dips (the skip off atmosphere) then surges back
    private func playSkipManeuver() {
        guard isContinuousActive else { return }
        // Brief drop
        let drop = CHHapticDynamicParameter(
            parameterID: .hapticIntensityControl, value: 0.1, relativeTime: 0)
        try? continuousPlayer?.sendParameters([drop], atTime: CHHapticTimeImmediate)

        // Surge back after 300ms (the re-contact with atmosphere)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let surge = CHHapticDynamicParameter(
                parameterID: .hapticIntensityControl, value: 0.8, relativeTime: 0)
            try? self.continuousPlayer?.sendParameters([surge], atTime: CHHapticTimeImmediate)
            self.playTransient(intensity: 0.7, sharpness: 0.6)
        }
    }

    /// Splashdown: stop reentry vibration, heavy impact, settling bounces
    private func playSplashdown() {
        stopContinuous()

        // Main impact
        playTransient(intensity: 1.0, sharpness: 0.7)

        // Bounces on water, each lighter than the last
        let bounces: [(TimeInterval, Float)] = [
            (0.2, 0.6), (0.4, 0.35), (0.6, 0.2), (0.85, 0.1),
        ]
        for (delay, intensity) in bounces {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.playTransient(intensity: intensity, sharpness: 0.15)
            }
        }
    }

    // MARK: - Primitives

    private func playTransient(intensity: Float, sharpness: Float) {
        guard supportsHaptics, let engine else { return }
        ensureRunning()

        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: 0
        )

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch { }
    }

    private func playDoubleTap(intensity: Float, sharpness: Float) {
        playTransient(intensity: intensity, sharpness: sharpness)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playTransient(intensity: intensity * 0.8, sharpness: sharpness)
        }
    }
}
