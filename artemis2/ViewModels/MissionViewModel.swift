//
//  MissionViewModel.swift
//  artemis2
//
//  Central mission state manager using Combine for reactive updates.
//  Controls simulation time, telemetry, phase progression, and challenges.
//

import Foundation
import Combine
import SwiftUI
import simd

@Observable
final class MissionViewModel {

    // MARK: - Mission State

    var missionTime: Double = -600 // Start at T-10 minutes
    var isRunning: Bool = false
    var timeWarp: TimeWarp = .realtime
    var currentPhase: MissionPhase = .prelaunch
    var telemetry: TelemetryData = .initial
    var overallProgress: Double = 0

    // MARK: - Spacecraft Position

    var spacecraftPosition: SIMD3<Float> = .zero
    var trajectoryPoints: [SIMD3<Float>] = []

    // MARK: - View State

    var viewMode: ViewMode = .external
    var showChallengeSheet: Bool = false
    var activeChallengePhase: MissionPhase? = nil
    var showMilestoneAlert: Bool = false
    var currentMilestone: MissionMilestone? = nil
    var showEducationalPopup: Bool = false

    // MARK: - Challenge State

    var challengeResults: [ChallengeResult] = []
    var totalScore: Int = 0

    // MARK: - Telemetry History (for Charts)

    var telemetryHistory: [TelemetrySnapshot] = []
    private var lastRecordedProgress: Double = -1
    private let recordingInterval: Double = 0.002 // every 0.2% of mission

    // MARK: - Mission Completion

    var showMissionComplete: Bool = false
    var peakSpeed: Double = 0
    var peakAltitude: Double = 0
    var peakGForce: Double = 0

    // MARK: - Audio

    var isAudioEnabled: Bool = true

    // MARK: - Countdown

    var countdownValue: Int = 10

    var isPrelaunch: Bool {
        missionTime < 0
    }

    var countdownString: String {
        if missionTime < 0 {
            let seconds = Int(abs(missionTime))
            let minutes = seconds / 60
            let secs = seconds % 60
            return String(format: "T-%d:%02d", minutes, secs)
        }
        return telemetry.formattedMET
    }

    // MARK: - Timer

    private var timer: Timer?
    private let tickInterval: TimeInterval = 1.0 / 30.0 // 30 FPS
    private var lastMilestoneIndex: Int = -1
    private var lastCountdownSecond: Int = Int.max
    private var previousPhase: MissionPhase = .prelaunch

    // MARK: - Initialization

    init() {
        trajectoryPoints = OrbitalMechanics.generateTrajectoryPoints(count: 600)
        updateState()
    }

    // MARK: - Simulation Control

    func startMission() {
        isRunning = true
        startTimer()
        HapticManager.shared.resumeContinuous()
        if isAudioEnabled {
            MissionAudioManager.shared.startAmbient(for: currentPhase)
        }
    }

    func pauseMission() {
        isRunning = false
        stopTimer()
        HapticManager.shared.pauseContinuous()
        if isAudioEnabled {
            MissionAudioManager.shared.pauseAmbient()
        }
    }

    func toggleAudio() {
        isAudioEnabled.toggle()
        if isAudioEnabled {
            MissionAudioManager.shared.startAmbient(for: currentPhase)
        } else {
            MissionAudioManager.shared.stop()
        }
    }

    func togglePlayPause() {
        if isRunning {
            pauseMission()
        } else {
            startMission()
        }
    }

    func setTimeWarp(_ warp: TimeWarp) {
        timeWarp = warp
    }

    func skipToPhase(_ phase: MissionPhase) {
        HapticManager.shared.stopContinuous()
        MissionAudioManager.shared.skipTo(missionTime: phase.startTime + 1)
        backfillTelemetryHistory(upTo: phase.startTime + 1)
        missionTime = phase.startTime + 1
        previousPhase = phase
        currentPhase = phase
        updateState()
    }

    /// Pre-compute telemetry snapshots for skipped mission time
    private func backfillTelemetryHistory(upTo targetTime: Double) {
        let startTime = max(0, missionTime)
        guard targetTime > startTime else { return }
        let steps = 100
        let stepSize = (targetTime - startTime) / Double(steps)
        for i in 0...steps {
            let t = startTime + Double(i) * stepSize
            let telem = OrbitalMechanics.computeTelemetry(missionTime: t)
            let phase = OrbitalMechanics.currentPhase(at: t)
            let snapshot = TelemetrySnapshot(
                missionTime: t,
                speed: telem.speed,
                altitude: telem.altitude,
                gForce: telem.gForce,
                phase: phase
            )
            telemetryHistory.append(snapshot)
            if telem.speed > peakSpeed { peakSpeed = telem.speed }
            if telem.altitude > peakAltitude { peakAltitude = telem.altitude }
            if telem.gForce > peakGForce { peakGForce = telem.gForce }
        }
        lastRecordedProgress = OrbitalMechanics.overallProgress(at: targetTime)
    }

    func resetMission() {
        pauseMission()
        HapticManager.shared.stopContinuous()
        MissionAudioManager.shared.reset()
        missionTime = -600
        lastMilestoneIndex = -1
        lastCountdownSecond = Int.max
        previousPhase = .prelaunch
        challengeResults = []
        totalScore = 0
        telemetryHistory = []
        lastRecordedProgress = -1
        peakSpeed = 0
        peakAltitude = 0
        peakGForce = 0
        showMissionComplete = false
        updateState()
    }

    // MARK: - Timer Management

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard isRunning else { return }

        let deltaTime = tickInterval * timeWarp.rawValue
        missionTime += deltaTime

        // Clamp to mission end
        if missionTime >= MissionConstants.totalMissionDuration {
            missionTime = MissionConstants.totalMissionDuration
            pauseMission()
            HapticManager.shared.stopContinuous()
            HapticManager.shared.missionComplete()
            MissionAudioManager.shared.stop()
            showMissionComplete = true
        }

        updateState()
        updateHaptics()
        if isAudioEnabled { MissionAudioManager.shared.update(missionTime: missionTime) }
        recordTelemetrySnapshot()
        checkMilestones()
    }

    // MARK: - State Update

    private func updateState() {
        // Update phase
        let newPhase: MissionPhase
        if missionTime < 0 {
            newPhase = .prelaunch
        } else {
            newPhase = OrbitalMechanics.currentPhase(at: missionTime)
        }

        if newPhase != previousPhase {
            HapticManager.shared.phaseTransition(from: previousPhase, to: newPhase)
            if isAudioEnabled { MissionAudioManager.shared.updatePhase(newPhase) }
            previousPhase = newPhase
        }
        currentPhase = newPhase

        // Update telemetry
        if missionTime >= 0 {
            telemetry = OrbitalMechanics.computeTelemetry(missionTime: missionTime)
        } else {
            telemetry = .initial
            telemetry.missionElapsedTime = missionTime
        }

        // Update spacecraft position
        if missionTime >= 0 {
            spacecraftPosition = OrbitalMechanics.spacecraftPosition(missionTime: missionTime)
        }

        // Update overall progress
        overallProgress = OrbitalMechanics.overallProgress(at: missionTime)
    }

    // MARK: - Haptic Feedback

    private func updateHaptics() {
        // Countdown ticks in the final 10 seconds before launch
        if missionTime > -10 && missionTime < 0 {
            let currentSecond = Int(ceil(abs(missionTime)))
            if currentSecond != lastCountdownSecond && currentSecond >= 1 && currentSecond <= 10 {
                lastCountdownSecond = currentSecond
                HapticManager.shared.countdownTick(secondsRemaining: currentSecond)
            }
        }

        // Dynamically update continuous intensity during thrust phases
        if currentPhase == .launch || currentPhase == .translunarInjection || currentPhase == .reentry {
            HapticManager.shared.updateContinuousIntensity(
                gForce: telemetry.gForce, phase: currentPhase)
        }
    }

    // MARK: - Milestone Checking

    private func checkMilestones() {
        let milestones = MissionMilestone.milestones
        for (index, milestone) in milestones.enumerated() {
            if index > lastMilestoneIndex &&
               missionTime >= milestone.missionTime &&
               missionTime < milestone.missionTime + 5 * timeWarp.rawValue {
                lastMilestoneIndex = index
                currentMilestone = milestone
                showMilestoneAlert = true
                HapticManager.shared.milestoneHaptic(name: milestone.name)
                if isAudioEnabled { MissionAudioManager.shared.onMilestone(name: milestone.name) }

                // If it's an interactive milestone, pause and show challenge
                if milestone.isInteractive {
                    pauseMission()
                    activeChallengePhase = milestone.phase
                    showChallengeSheet = true
                }
                break
            }
        }
    }

    // MARK: - Challenge Management

    func submitChallengeResult(_ result: ChallengeResult) {
        challengeResults.append(result)
        totalScore = Int(challengeResults.reduce(0.0) { $0 + $1.score })
        showChallengeSheet = false
        activeChallengePhase = nil

        // Resume mission after challenge
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.startMission()
        }
    }

    func skipChallenge() {
        showChallengeSheet = false
        activeChallengePhase = nil
        startMission()
    }

    // MARK: - Telemetry Recording

    private func recordTelemetrySnapshot() {
        guard missionTime >= 0 else { return }
        let progress = overallProgress
        guard progress - lastRecordedProgress >= recordingInterval else { return }
        lastRecordedProgress = progress

        let snapshot = TelemetrySnapshot(
            missionTime: missionTime,
            speed: telemetry.speed,
            altitude: telemetry.altitude,
            gForce: telemetry.gForce,
            phase: currentPhase
        )
        telemetryHistory.append(snapshot)

        if telemetry.speed > peakSpeed { peakSpeed = telemetry.speed }
        if telemetry.altitude > peakAltitude { peakAltitude = telemetry.altitude }
        if telemetry.gForce > peakGForce { peakGForce = telemetry.gForce }
    }

    // MARK: - Mission Stats

    var missionDurationFormatted: String {
        let totalSeconds = MissionConstants.totalMissionDuration
        let days = Int(totalSeconds) / 86400
        let hours = (Int(totalSeconds) % 86400) / 3600
        return "\(days) days, \(hours) hours"
    }

    var averageChallengeScore: Double {
        guard !challengeResults.isEmpty else { return 0 }
        return challengeResults.reduce(0.0) { $0 + $1.score } / Double(challengeResults.count)
    }

    var challengesPassed: Int {
        challengeResults.filter(\.passed).count
    }

    var missionRating: String {
        let avg = averageChallengeScore
        if challengeResults.isEmpty { return "Unrated" }
        if avg >= 90 { return "Outstanding" }
        if avg >= 75 { return "Excellent" }
        if avg >= 60 { return "Good" }
        if avg >= 40 { return "Satisfactory" }
        return "Needs Improvement"
    }

    // MARK: - Convenience

    var phaseProgressValue: Double {
        if missionTime < 0 {
            return (missionTime + 600) / 600
        }
        return OrbitalMechanics.phaseProgress(at: missionTime)
    }

    var nextMilestone: MissionMilestone? {
        MissionMilestone.milestones.first { $0.missionTime > missionTime }
    }

    var distanceToNextMilestone: String {
        guard let next = nextMilestone else { return "Mission Complete" }
        let delta = next.missionTime - missionTime
        if delta > 3600 {
            return String(format: "%.1f hours", delta / 3600)
        } else if delta > 60 {
            return String(format: "%.0f min", delta / 60)
        }
        return String(format: "%.0f sec", delta)
    }

    var missionComplete: Bool {
        missionTime >= MissionConstants.totalMissionDuration
    }
}
