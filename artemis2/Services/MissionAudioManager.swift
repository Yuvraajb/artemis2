//
//  MissionAudioManager.swift
//  artemis2
//
//  Three-layer audio system for the cinematic prologue and mission:
//  1. Intro  — dark_noise.mp3 (bassy dark atmosphere during prologue)
//  2. Neil   — neil.mp3 (Armstrong's quote, plays once over the bass)
//  3. Ambient — background_music.mp3 with spatial processing (main app)
//

import AVFoundation

final class MissionAudioManager {
    static let shared = MissionAudioManager()

    // MARK: - Intro Audio (dark_noise.mp3)

    private var introPlayer: AVAudioPlayer?
    private var introFadeTimer: Timer?

    // MARK: - Neil Audio (neil.mp3)

    private var neilPlayer: AVAudioPlayer?
    private var neilFadeTimer: Timer?

    // MARK: - Ambient Audio Graph (background_music.mp3)

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var environmentNode: AVAudioEnvironmentNode?
    private var reverbUnit: AVAudioUnitReverb?
    private var audioBuffer: AVAudioPCMBuffer?
    private var processingFormat: AVAudioFormat?
    private var useSpatialOrbit = false

    // MARK: - State

    private var currentPhaseVolume: Float = 0.6
    private var fadeTimer: Timer?
    private var orbitTimer: Timer?
    private var orbitAngle: Float = 0
    private var isPlaying = false

    var isEnabled: Bool = true {
        didSet {
            if isEnabled { resumeAmbient() }
            else { pauseAmbient() }
        }
    }

    // MARK: - Init

    private init() {
        configureAudioSession()
        loadIntroAudio()
        loadNeilAudio()
        loadAmbientAudio()
        buildGraph()

        NotificationCenter.default.addObserver(
            self, selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification, object: nil
        )
    }

    // MARK: - Audio Loading

    private func loadIntroAudio() {
        guard let url = Bundle.main.url(forResource: "dark_noise", withExtension: "mp3") else { return }
        do {
            introPlayer = try AVAudioPlayer(contentsOf: url)
            introPlayer?.numberOfLoops = -1
            introPlayer?.volume = 0
            introPlayer?.prepareToPlay()
        } catch { }
    }

    private func loadNeilAudio() {
        guard let url = Bundle.main.url(forResource: "neil", withExtension: "mp3") else { return }
        do {
            neilPlayer = try AVAudioPlayer(contentsOf: url)
            neilPlayer?.numberOfLoops = 0
            neilPlayer?.volume = 0
            neilPlayer?.prepareToPlay()
        } catch { }
    }

    private func loadAmbientAudio() {
        guard let url = Bundle.main.url(forResource: "background_music", withExtension: "mp3") else { return }
        do {
            let file = try AVAudioFile(forReading: url)
            processingFormat = file.processingFormat
            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: file.processingFormat,
                frameCapacity: AVAudioFrameCount(file.length)
            ) else { return }
            try file.read(into: buffer)
            audioBuffer = buffer
        } catch { }
    }

    // MARK: - Graph Construction

    private func buildGraph() {
        guard let format = processingFormat else { return }

        engine.attach(playerNode)

        if format.channelCount == 1 {
            let env = AVAudioEnvironmentNode()
            environmentNode = env
            engine.attach(env)

            engine.connect(playerNode, to: env, format: format)
            engine.connect(env, to: engine.mainMixerNode, format: nil)

            playerNode.renderingAlgorithm = .HRTFHQ
            playerNode.position = AVAudio3DPoint(x: 0, y: 1.5, z: -0.5)

            env.reverbParameters.enable = true
            env.reverbParameters.level = -15
            env.reverbParameters.loadFactoryReverbPreset(.cathedral)

            env.distanceAttenuationParameters.distanceAttenuationModel = .inverse
            env.distanceAttenuationParameters.referenceDistance = 1.0
            env.distanceAttenuationParameters.maximumDistance = 50.0
            env.distanceAttenuationParameters.rolloffFactor = 0.3

            useSpatialOrbit = true
        } else {
            let reverb = AVAudioUnitReverb()
            reverb.loadFactoryPreset(.cathedral)
            reverb.wetDryMix = 30
            reverbUnit = reverb

            engine.attach(reverb)
            engine.connect(playerNode, to: reverb, format: format)
            engine.connect(reverb, to: engine.mainMixerNode, format: nil)

            useSpatialOrbit = false
        }

        playerNode.volume = 0
        engine.prepare()
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch { }
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        if type == .ended, isEnabled {
            if isPlaying {
                try? engine.start()
                scheduleAndPlay()
            }
        }
    }

    // MARK: - Intro Audio (Prologue Bass)

    func startIntro(fadeDuration: TimeInterval = 3.0, targetVolume: Float = 0.7) {
        guard introPlayer != nil else { return }
        configureAudioSession()
        introPlayer?.volume = 0
        introPlayer?.play()
        animatePlayerVolume(introPlayer, timer: &introFadeTimer, to: targetVolume, duration: fadeDuration)
    }

    func stopIntro() {
        introFadeTimer?.invalidate()
        introFadeTimer = nil
        introPlayer?.stop()
        introPlayer?.volume = 0
    }

    // MARK: - Neil Audio

    func startNeil(fadeDuration: TimeInterval = 1.5, targetVolume: Float = 0.85) {
        guard neilPlayer != nil else { return }
        configureAudioSession()
        neilPlayer?.currentTime = 0
        neilPlayer?.volume = 0
        neilPlayer?.play()
        animatePlayerVolume(neilPlayer, timer: &neilFadeTimer, to: targetVolume, duration: fadeDuration)
    }

    func fadeOutNeil(duration: TimeInterval = 2.0) {
        animatePlayerVolume(neilPlayer, timer: &neilFadeTimer, to: 0, duration: duration) { [weak self] in
            self?.neilPlayer?.stop()
        }
    }

    func stopNeil() {
        neilFadeTimer?.invalidate()
        neilFadeTimer = nil
        neilPlayer?.stop()
        neilPlayer?.volume = 0
    }

    // MARK: - Crossfade (prologue → ambient)

    func crossfadeToAmbient(duration: TimeInterval = 3.0) {
        animatePlayerVolume(introPlayer, timer: &introFadeTimer, to: 0, duration: duration) { [weak self] in
            self?.introPlayer?.stop()
        }
        stopNeil()
        fadeInAmbient(duration: duration)
    }

    // MARK: - Generic AVAudioPlayer Volume Animation

    private func animatePlayerVolume(
        _ player: AVAudioPlayer?,
        timer: inout Timer?,
        to target: Float,
        duration: TimeInterval,
        completion: (() -> Void)? = nil
    ) {
        timer?.invalidate()
        let fps = 60.0
        let totalSteps = Int(duration * fps)
        guard totalSteps > 0, let player else {
            player?.volume = target
            completion?()
            return
        }

        let startVol = player.volume
        let delta = target - startVol
        var step = 0

        let newTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / fps, repeats: true) { t in
            step += 1
            let p = Float(step) / Float(totalSteps)
            let eased = p < 0.5 ? 2 * p * p : 1 - pow(-2 * p + 2, 2) / 2
            player.volume = startVol + delta * eased
            if step >= totalSteps {
                t.invalidate()
                player.volume = target
                completion?()
            }
        }
        timer = newTimer
    }

    // MARK: - Ambient Playback (double-buffered for gapless looping)

    private func scheduleAndPlay() {
        guard audioBuffer != nil else { return }
        scheduleNextBuffer()
        scheduleNextBuffer()
        playerNode.play()
    }

    private func scheduleNextBuffer() {
        guard let buffer = audioBuffer else { return }
        playerNode.scheduleBuffer(buffer) { [weak self] in
            guard let self, self.isPlaying else { return }
            self.scheduleNextBuffer()
        }
    }

    func fadeInAmbient(to phase: MissionPhase = .prelaunch, duration: TimeInterval = 3.0) {
        guard isEnabled, audioBuffer != nil else { return }
        configureAudioSession()

        currentPhaseVolume = ambientVolume(for: phase)
        playerNode.volume = 0

        do {
            if !engine.isRunning { try engine.start() }
        } catch { return }

        if !isPlaying {
            scheduleAndPlay()
            isPlaying = true
        }

        if useSpatialOrbit { startOrbit() }
        animateVolume(to: currentPhaseVolume, duration: duration)
    }

    // MARK: - Ambient Control

    func startAmbient(for phase: MissionPhase) {
        if !isPlaying {
            fadeInAmbient(to: phase, duration: 2.0)
        } else {
            updatePhase(phase)
        }
    }

    func fadeOutAmbient(duration: TimeInterval = 3.0) {
        guard isPlaying else { return }
        animateVolume(to: 0, duration: duration)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) { [weak self] in
            self?.stopAmbient()
        }
    }

    func stopAmbient() {
        fadeTimer?.invalidate()
        fadeTimer = nil
        orbitTimer?.invalidate()
        orbitTimer = nil
        playerNode.stop()
        if engine.isRunning { engine.stop() }
        isPlaying = false
    }

    func pauseAmbient() {
        playerNode.pause()
        orbitTimer?.invalidate()
        orbitTimer = nil
    }

    func resumeAmbient() {
        guard isEnabled, isPlaying else { return }
        if !engine.isRunning { try? engine.start() }
        playerNode.play()
        if useSpatialOrbit { startOrbit() }
    }

    func updatePhase(_ phase: MissionPhase) {
        currentPhaseVolume = ambientVolume(for: phase)
        animateVolume(to: currentPhaseVolume, duration: 1.5)
    }

    // MARK: - Ambient Volume Animation

    private func animateVolume(to target: Float, duration: TimeInterval) {
        fadeTimer?.invalidate()
        let fps = 60.0
        let totalSteps = Int(duration * fps)
        guard totalSteps > 0 else { playerNode.volume = target; return }

        let startVol = playerNode.volume
        let delta = target - startVol
        var step = 0

        fadeTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / fps, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            step += 1
            let t = Float(step) / Float(totalSteps)
            let eased = t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
            self.playerNode.volume = startVol + delta * eased
            if step >= totalSteps {
                timer.invalidate()
                self.fadeTimer = nil
                self.playerNode.volume = target
            }
        }
    }

    // MARK: - Spatial Orbit

    private func startOrbit() {
        orbitTimer?.invalidate()
        let interval: TimeInterval = 1.0 / 30.0
        orbitTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.orbitAngle += 0.002
            let radius: Float = 3.0
            let x = radius * sin(self.orbitAngle)
            let z = radius * cos(self.orbitAngle)
            let y: Float = 1.5 + 0.3 * sin(self.orbitAngle * 0.7)
            self.playerNode.position = AVAudio3DPoint(x: x, y: y, z: z)
        }
    }

    // MARK: - Phase Volumes

    private func ambientVolume(for phase: MissionPhase) -> Float {
        switch phase {
        case .prelaunch:           return 0.6
        case .launch:              return 0.25
        case .earthOrbit:          return 0.7
        case .translunarInjection: return 0.35
        case .translunarCoast:     return 0.8
        case .lunarFlyby:          return 0.5
        case .returnTransit:       return 0.8
        case .reentry:             return 0.25
        }
    }

    // MARK: - Lifecycle

    func stop() {
        stopIntro()
        stopNeil()
        stopAmbient()
    }

    func reset() {
        stop()
        playerNode.volume = 0
        orbitAngle = 0
    }
}
