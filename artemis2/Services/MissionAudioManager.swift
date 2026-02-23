//
//  MissionAudioManager.swift
//  artemis2
//
//  Procedural ambient audio + AVSpeechSynthesizer narration.
//  The ambient drone is generated from sine waves — zero bundled assets.
//  The narration uses the highest-quality on-device voice available.
//

import AVFoundation

final class MissionAudioManager: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = MissionAudioManager()

    // MARK: - Audio Components

    private let synthesizer = AVSpeechSynthesizer()
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var ambientBuffer: AVAudioPCMBuffer?
    private var selectedVoice: AVSpeechSynthesisVoice?

    // MARK: - State

    private var playedCueIDs: Set<String> = []
    private var lastProcessedTime: Double = -700
    private var isAmbientRunning = false
    private var isSpeaking = false
    private var currentPhaseVolume: Float = 0.6

    // MARK: - Init

    private override init() {
        super.init()
        synthesizer.delegate = self
        selectedVoice = pickVoice()
        prepareAmbientEngine()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    // MARK: - Voice Selection
    // Pick the most natural-sounding English voice available on this device.

    private func pickVoice() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == "en-US" }
            .sorted { $0.quality.rawValue > $1.quality.rawValue }
        return voices.first ?? AVSpeechSynthesisVoice(language: "en-US")
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true)
        } catch { }
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        if type == .ended {
            try? audioEngine?.start()
            if isAmbientRunning, let player = playerNode, !player.isPlaying {
                player.play()
            }
        }
    }

    // MARK: - Procedural Ambient Audio
    // Warm sine-wave drone with slow breathing LFO. Generated from math.

    private func prepareAmbientEngine() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()

        guard let engine = audioEngine, let player = playerNode else { return }

        engine.attach(player)

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)

        ambientBuffer = generateAmbientBuffer(format: format)
    }

    private func generateAmbientBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let duration: Double = 12.0 // Seamless loop period
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount

        guard let data = buffer.floatChannelData?[0] else { return nil }

        let fundamentalFreq = 55.0   // A1 — warm bass
        let fifthFreq = 82.5         // E2 — perfect fifth harmony
        let octaveFreq = 110.0       // A2 — octave
        let lfoFreq = 1.0 / 12.0     // One breath per loop cycle

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate

            let lfo = Float(0.65 + 0.35 * sin(t * lfoFreq * 2.0 * .pi))

            let fundamental = Float(sin(t * fundamentalFreq * 2.0 * .pi)) * 0.035
            let fifth       = Float(sin(t * fifthFreq * 2.0 * .pi)) * 0.025
            let octave      = Float(sin(t * octaveFreq * 2.0 * .pi)) * 0.018

            data[frame] = (fundamental + fifth + octave) * lfo
        }

        return buffer
    }

    // MARK: - Ambient Control

    func startAmbient(for phase: MissionPhase) {
        guard let engine = audioEngine, let player = playerNode, let buffer = ambientBuffer else { return }

        configureAudioSession()

        do {
            if !engine.isRunning {
                try engine.start()
            }
            currentPhaseVolume = ambientVolume(for: phase)
            player.volume = currentPhaseVolume

            player.scheduleBuffer(buffer, at: nil, options: .loops)
            player.play()
            isAmbientRunning = true
        } catch { }
    }

    func stopAmbient() {
        playerNode?.stop()
        audioEngine?.stop()
        isAmbientRunning = false
    }

    func pauseAmbient() {
        playerNode?.pause()
    }

    func resumeAmbient() {
        guard isAmbientRunning else { return }
        if audioEngine?.isRunning == false {
            try? audioEngine?.start()
        }
        if let player = playerNode, let buffer = ambientBuffer, !player.isPlaying {
            player.scheduleBuffer(buffer, at: nil, options: .loops)
            player.play()
        }
        playerNode?.volume = isSpeaking ? currentPhaseVolume * 0.3 : currentPhaseVolume
    }

    func updatePhase(_ phase: MissionPhase) {
        currentPhaseVolume = ambientVolume(for: phase)
        if !isSpeaking {
            playerNode?.volume = currentPhaseVolume
        }
    }

    private func ambientVolume(for phase: MissionPhase) -> Float {
        switch phase {
        case .prelaunch:              return 0.6
        case .launch:                 return 0.25  // quieter during loud visual action
        case .earthOrbit:             return 0.7
        case .translunarInjection:    return 0.35
        case .translunarCoast:        return 0.8   // full zen for the long coast
        case .lunarFlyby:             return 0.5   // subtler for emotional impact
        case .returnTransit:          return 0.8
        case .reentry:                return 0.25  // quieter during intense visuals
        }
    }

    // MARK: - Ducking (lower ambient during speech)

    private func duckAmbient() {
        playerNode?.volume = currentPhaseVolume * 0.3
    }

    private func unduckAmbient() {
        playerNode?.volume = currentPhaseVolume
    }

    // MARK: - Speech

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .word)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = selectedVoice
        utterance.rate = 0.46
        utterance.pitchMultiplier = 0.95
        utterance.volume = 0.85
        utterance.preUtteranceDelay = 0.3
        utterance.postUtteranceDelay = 0.5

        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    // MARK: - AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isSpeaking = true
        duckAmbient()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        unduckAmbient()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        unduckAmbient()
    }

    // MARK: - Narration Cue Processing

    /// Called every tick — checks for time-based narration cues
    func update(missionTime: Double) {
        let cues = NarrationScript.timeCues

        var latestCue: TimedNarration?

        for cue in cues {
            guard !playedCueIDs.contains(cue.id) else { continue }
            guard cue.time > lastProcessedTime && cue.time <= missionTime else { continue }

            playedCueIDs.insert(cue.id)
            latestCue = cue
        }

        // Play only the most recent cue to avoid speech pile-up during time warp
        if let cue = latestCue {
            speak(cue.text)
        }

        lastProcessedTime = missionTime
    }

    /// Called when a milestone occurs
    func onMilestone(name: String) {
        guard let cue = NarrationScript.milestoneCue(for: name) else { return }
        guard !playedCueIDs.contains(cue.id) else { return }
        playedCueIDs.insert(cue.id)
        speak(cue.text)
    }

    /// Called when the user skips to a phase — advance without playing old cues
    func skipTo(missionTime: Double) {
        for cue in NarrationScript.timeCues where cue.time <= missionTime {
            playedCueIDs.insert(cue.id)
        }
        lastProcessedTime = missionTime
    }

    // MARK: - Lifecycle

    func stop() {
        stopSpeaking()
        stopAmbient()
    }

    func reset() {
        stop()
        playedCueIDs.removeAll()
        lastProcessedTime = -700
        isSpeaking = false
    }
}
