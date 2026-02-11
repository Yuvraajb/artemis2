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

    // MARK: - Initialization

    init() {
        trajectoryPoints = OrbitalMechanics.generateTrajectoryPoints(count: 600)
        updateState()
    }

    // MARK: - Simulation Control

    func startMission() {
        isRunning = true
        startTimer()
    }

    func pauseMission() {
        isRunning = false
        stopTimer()
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
        missionTime = phase.startTime + 1
        updateState()
    }

    func resetMission() {
        pauseMission()
        missionTime = -600
        lastMilestoneIndex = -1
        challengeResults = []
        totalScore = 0
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
        }

        updateState()
        checkMilestones()
    }

    // MARK: - State Update

    private func updateState() {
        // Update phase
        if missionTime < 0 {
            currentPhase = .prelaunch
        } else {
            currentPhase = OrbitalMechanics.currentPhase(at: missionTime)
        }

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
