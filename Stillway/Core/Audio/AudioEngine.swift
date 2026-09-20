import MediaPlayer
@preconcurrency import AVFoundation
import Foundation
import Observation

enum JourneyPhase: String, Sendable {
    case idle
    case arrival
    case deepZone
    case slowReset
}

private final class BinauralSynthState: @unchecked Sendable {
    var carrierHz: Double = 216.0
    var beatHz: Double = 0.0
    var isMuted: Bool = true
    var leftPhase: Double = 0.0
    var rightPhase: Double = 0.0
}

@Observable
@MainActor
final class AudioEngine {
    private let engine = AVAudioEngine()
    private let masterMixer = AVAudioMixerNode()
    private let primaryMixer = AVAudioMixerNode()
    private let secondaryMixer = AVAudioMixerNode()
    private let binauralMixer = AVAudioMixerNode()
    private let primaryPlayer = AVAudioPlayerNode()
    private let secondaryPlayer = AVAudioPlayerNode()
    private var binauralSourceNode: AVAudioSourceNode?
    private let synthState = BinauralSynthState()

    private(set) var isPlaying = false
    /// True when the last scheduled bed came from a bundled audio file (not procedural noise).
    private(set) var isUsingFileBed = false
    var primarySound: Sound?
    var secondarySound: Sound?
    var journeyPhase: JourneyPhase = .idle
    var lastLoadNote: String?

    var primaryVolume: Float = 0.8 {
        didSet { primaryMixer.outputVolume = primaryVolume }
    }
    var secondaryVolume: Float = 0.5 {
        didSet { secondaryMixer.outputVolume = secondaryVolume }
    }

    /// Active binaural / carrier tone selection (bound from SoundPickerSheet / mixer).
    var binauralTone: BinauralTone = .off

    func setBinauralTone(_ value: BinauralTone) {
        binauralTone = value
        synthState.beatHz = value.beatHz
        synthState.isMuted = (value == .off)
        fadeTask?.cancel()
        if value == .off {
            fadeTask = Task { await fadeAsync(to: 0, on: binauralMixer, duration: 0.8) }
        } else {
            startEngineIfNeeded()
            fadeTask = Task { await fadeAsync(to: 0.45, on: binauralMixer, duration: 1.2) }
        }
    }

    var isHeadphonesConnected: Bool { headphonesConnected }
    private(set) var headphonesConnected = false

    private var fadeTask: Task<Void, Never>?
    private var journeyTask: Task<Void, Never>?
    private var sessionStart: Date?
    private var sessionDuration: TimeInterval = 30 * 60
    private var untilArrival = false
    private var routeObserver: NSObjectProtocol?
    private var interruptionObserver: NSObjectProtocol?

    init() {
        attachGraph()
        observeRouteChanges()
        observeInterruptions()
        refreshHeadphones()
        setupRemoteCommandCenter()
    }

    func play(sound: Sound, fadeDuration: Double = 1.5) {
        primarySound = sound
        schedule(player: primaryPlayer, sound: sound)
        startEngineIfNeeded()
        primaryPlayer.play()
        if let sec = secondarySound {
            schedule(player: secondaryPlayer, sound: sec)
            secondaryPlayer.play()
        }
        isPlaying = true
        sessionStart = Date()
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        updateNowPlayingInfo()
        journeyPhase = .arrival
        fadeTask?.cancel()
        fadeTask = Task {
            await fadeAsync(to: primaryVolume, on: primaryMixer, duration: fadeDuration)
            if secondarySound != nil {
                await fadeAsync(to: secondaryVolume, on: secondaryMixer, duration: fadeDuration)
            }
            if binauralTone != .off {
                await fadeAsync(to: 0.45, on: binauralMixer, duration: fadeDuration)
            }
        }
        HapticEngine.success()
    }

    func playSecondary(sound: Sound) {
        secondarySound = sound
        schedule(player: secondaryPlayer, sound: sound)
        startEngineIfNeeded()
        secondaryPlayer.play()
        fadeTask?.cancel()
        fadeTask = Task {
            await fadeAsync(to: secondaryVolume, on: secondaryMixer, duration: 1.5)
        }
    }

    func stopSecondary() {
        fadeTask?.cancel()
        fadeTask = Task { [weak self] in
            guard let self else { return }
            await self.fadeAsync(to: 0, on: self.secondaryMixer, duration: 1.0)
            self.secondaryPlayer.stop()
            self.secondarySound = nil
        }
    }

    func stop(fadeDuration: Double = 2.0) {
        journeyTask?.cancel()
        fadeTask?.cancel()
        fadeTask = Task { [weak self] in
            guard let self else { return }
            await self.fadeAsync(to: 0, on: self.primaryMixer, duration: fadeDuration)
            await self.fadeAsync(to: 0, on: self.secondaryMixer, duration: fadeDuration)
            await self.fadeAsync(to: 0, on: self.binauralMixer, duration: fadeDuration)
            self.primaryPlayer.stop()
            self.secondaryPlayer.stop()
            self.isPlaying = false
            if let start = self.sessionStart {
                HealthKitManager.shared.saveMindfulSession(startDate: start, endDate: Date())
            }
            self.sessionStart = nil
            self.journeyPhase = .idle
            self.clearNowPlayingInfo()
            DispatchQueue.main.async {
                UIApplication.shared.isIdleTimerDisabled = false
            }
            HapticEngine.soft()
        }
    }

    func toggle() {
        if isPlaying {
            stop()
        } else if let sound = primarySound ?? Sound.find("tokyo_rain") {
            play(sound: sound)
        }
    }

    func startJourneyArc(minutes: Double) {
        untilArrival = false
        sessionDuration = minutes * 60
        sessionStart = Date()
        journeyTask?.cancel()
        journeyTask = Task { [weak self] in
            while let self, self.isPlaying, !Task.isCancelled {
                self.updateJourneyArc()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    func setTimer(minutes: Int?) {
        if let minutes {
            untilArrival = false
            sessionDuration = TimeInterval(minutes * 60)
        } else {
            untilArrival = true
            sessionDuration = 45 * 60
        }
    }

    func setMasterVolume(_ vol: Float, duration: Double) {
        fadeTask?.cancel()
        fadeTask = Task { await fadeAsync(to: vol, on: masterMixer, duration: duration) }
    }

    func updateJourneyArc() {
        guard isPlaying, let sessionStart, !untilArrival else { return }
        let elapsed = Date().timeIntervalSince(sessionStart)
        let progress = min(1, elapsed / sessionDuration)
        if progress < 0.15 {
            journeyPhase = .arrival
            masterMixer.outputVolume = 0.65
        } else if progress < 0.85 {
            journeyPhase = .deepZone
            masterMixer.outputVolume = 1.0
        } else {
            journeyPhase = .slowReset
            let tail = Float((progress - 0.85) / 0.15)
            masterMixer.outputVolume = max(0.3, 1.0 - tail * 0.7)
            if progress >= 1 {
                playCompletionChime()
                stop(fadeDuration: 3.0)
            }
        }
    }

    var remainingSeconds: Int {
        guard isPlaying, let sessionStart else { return Int(sessionDuration) }
        return max(0, Int(sessionDuration - Date().timeIntervalSince(sessionStart)))
    }

    private func attachGraph() {
        engine.attach(primaryPlayer)
        engine.attach(secondaryPlayer)
        engine.attach(primaryMixer)
        engine.attach(secondaryMixer)
        engine.attach(binauralMixer)
        engine.attach(masterMixer)

        let format = Self.playbackFormat
        engine.connect(primaryPlayer, to: primaryMixer, format: format)
        engine.connect(secondaryPlayer, to: secondaryMixer, format: format)

        let synth = self.synthState
        let sampleRate = format.sampleRate
        let sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard abl.count >= 2,
                  let leftPtr = abl[0].mData?.assumingMemoryBound(to: Float.self),
                  let rightPtr = abl[1].mData?.assumingMemoryBound(to: Float.self) else {
                return noErr
            }

            if synth.isMuted || synth.beatHz <= 0 {
                memset(leftPtr, 0, Int(frameCount) * MemoryLayout<Float>.size)
                memset(rightPtr, 0, Int(frameCount) * MemoryLayout<Float>.size)
                return noErr
            }

            let carrier = synth.carrierHz
            let beat = synth.beatHz
            let leftFreq = carrier
            let rightFreq = carrier + beat
            let twoPi = 2.0 * Double.pi
            let leftDelta = (twoPi * leftFreq) / sampleRate
            let rightDelta = (twoPi * rightFreq) / sampleRate
            let amplitude: Float = 0.09

            var lPhase = synth.leftPhase
            var rPhase = synth.rightPhase

            for i in 0..<Int(frameCount) {
                leftPtr[i] = Float(sin(lPhase)) * amplitude
                rightPtr[i] = Float(sin(rPhase)) * amplitude
                lPhase += leftDelta
                if lPhase >= twoPi { lPhase -= twoPi }
                rPhase += rightDelta
                if rPhase >= twoPi { rPhase -= twoPi }
            }

            synth.leftPhase = lPhase
            synth.rightPhase = rPhase
            return noErr
        }
        binauralSourceNode = sourceNode
        engine.attach(sourceNode)
        engine.connect(sourceNode, to: binauralMixer, format: format)

        engine.connect(primaryMixer, to: masterMixer, format: format)
        engine.connect(secondaryMixer, to: masterMixer, format: format)
        engine.connect(binauralMixer, to: masterMixer, format: format)
        engine.connect(masterMixer, to: engine.mainMixerNode, format: format)

        primaryMixer.outputVolume = primaryVolume
        secondaryMixer.outputVolume = 0
        binauralMixer.outputVolume = 0
        masterMixer.outputVolume = 1
    }

    private static let playbackFormat = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!

    private func startEngineIfNeeded() {
        guard !engine.isRunning else { return }
        try? engine.start()
    }

    private func schedule(player: AVAudioPlayerNode, sound: Sound) {
        player.stop()
        player.reset()
        if let fileBuffer = loadBuffer(for: sound) {
            isUsingFileBed = true
            lastLoadNote = nil
            player.scheduleBuffer(fileBuffer, at: nil, options: .loops)
        } else {
            isUsingFileBed = false
            lastLoadNote = "missing:\(sound.fileName)"
            player.scheduleBuffer(Self.makeProceduralBuffer(for: sound), at: nil, options: .loops)
        }
    }

    private func loadBuffer(for sound: Sound) -> AVAudioPCMBuffer? {
        guard let url = findSoundURL(for: sound) else { return nil }
        guard let file = try? AVAudioFile(forReading: url) else { return nil }
        let frameCount = AVAudioFrameCount(file.length)
        guard frameCount > 0 else { return nil }
        guard let source = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: frameCount) else { return nil }
        do {
            try file.read(into: source)
        } catch {
            return nil
        }
        return convert(buffer: source, to: Self.playbackFormat)
    }

    private func findSoundURL(for sound: Sound) -> URL? {
        let extensions = ["m4a", "mp3", "wav", "caf", "aac", "M4A", "MP3", "WAV"]
        for ext in extensions {
            if let url = Bundle.main.url(forResource: sound.fileName, withExtension: ext, subdirectory: "Sounds") {
                return url
            }
            if let url = Bundle.main.url(forResource: sound.fileName, withExtension: ext, subdirectory: "Resources/Sounds") {
                return url
            }
            if let url = Bundle.main.url(forResource: sound.fileName, withExtension: ext) {
                return url
            }
        }
        // Last resort: scan the whole resource bundle (case-insensitive stem match).
        guard let root = Bundle.main.resourceURL else { return nil }
        let allowed = Set(extensions.map { $0.lowercased() })
        if let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let url as URL in enumerator {
                let ext = url.pathExtension.lowercased()
                guard allowed.contains(ext) else { continue }
                if url.deletingPathExtension().lastPathComponent.caseInsensitiveCompare(sound.fileName) == .orderedSame {
                    return url
                }
            }
        }
        return nil
    }

    private func convert(buffer: AVAudioPCMBuffer, to format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let same =
            abs(buffer.format.sampleRate - format.sampleRate) < 0.5
            && buffer.format.channelCount == format.channelCount
            && buffer.format.commonFormat == format.commonFormat
        if same { return buffer }
        guard let converter = AVAudioConverter(from: buffer.format, to: format) else { return nil }
        let ratio = format.sampleRate / max(buffer.format.sampleRate, 1)
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 64
        guard let out = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else { return nil }

        // AVAudioConverterInputBlock is @Sendable; keep mutable state off the stack capture list.
        final class FeedState: @unchecked Sendable {
            var didFeed = false
            let source: AVAudioPCMBuffer
            init(_ source: AVAudioPCMBuffer) { self.source = source }
        }
        let state = FeedState(buffer)
        var error: NSError?
        let status = converter.convert(to: out, error: &error) { _, outStatus in
            if state.didFeed {
                outStatus.pointee = .noDataNow
                return nil
            }
            state.didFeed = true
            outStatus.pointee = .haveData
            return state.source
        }
        guard error == nil, status != .error, out.frameLength > 0 else { return nil }
        return out
    }

    private static func makeProceduralBuffer(for sound: Sound) -> AVAudioPCMBuffer {
        let sampleRate = Self.playbackFormat.sampleRate
        let frames = AVAudioFrameCount(sampleRate * 10)
        let format = Self.playbackFormat
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames
        var rng = SplitMix64(state: UInt64(sound.id.utf8.reduce(0) { $0 &+ UInt64($1) }) &+ 0x9E37_79B9)
        let left = buffer.floatChannelData![0]
        let right = buffer.floatChannelData![1]
        let character = proceduralCharacter(for: sound)
        var pink = Array(repeating: 0.0, count: 7)
        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate
            let white = rng.nextNormalized()
            pink[0] = 0.99886 * pink[0] + white * 0.0555179
            pink[1] = 0.99332 * pink[1] + white * 0.0750759
            pink[2] = 0.96900 * pink[2] + white * 0.1538520
            pink[3] = 0.86650 * pink[3] + white * 0.3104856
            pink[4] = 0.55000 * pink[4] + white * 0.5329522
            pink[5] = -0.7616 * pink[5] - white * 0.0168980
            let noise = pink.reduce(0, +) + white * 0.5362
            pink[6] = white * 0.5362
            let tone =
                sin(2 * .pi * character.toneHz * t) * character.toneMix
                + sin(2 * .pi * character.toneHz * 0.5 * t) * character.toneMix * 0.35
                + sin(2 * .pi * character.lfoHz * t) * character.lfoDepth
            let shaped = noise * character.noiseMix + tone
            let envelope = 0.85 + 0.15 * sin(2 * .pi * character.breathHz * t)
            let value = Float(max(-1, min(1, shaped * character.gain * envelope)))
            left[i] = value
            right[i] = value * Float(character.stereo)
        }
        return buffer
    }

    private struct ProceduralCharacter {
        var toneHz: Double
        var toneMix: Double
        var noiseMix: Double
        var lfoHz: Double
        var lfoDepth: Double
        var breathHz: Double
        var gain: Double
        var stereo: Double
    }

    private static func proceduralCharacter(for sound: Sound) -> ProceduralCharacter {
        switch sound.id {
        case "tokyo_metro", "paris_metro":
            return ProceduralCharacter(toneHz: 92, toneMix: 0.08, noiseMix: 0.55, lfoHz: 0.35, lfoDepth: 0.04, breathHz: 0.08, gain: 0.07, stereo: 0.94)
        case "shinkansen", "deep_train":
            return ProceduralCharacter(toneHz: 68, toneMix: 0.12, noiseMix: 0.48, lfoHz: 0.18, lfoDepth: 0.05, breathHz: 0.05, gain: 0.075, stereo: 0.97)
        case "istanbul_ferry":
            return ProceduralCharacter(toneHz: 110, toneMix: 0.06, noiseMix: 0.42, lfoHz: 0.12, lfoDepth: 0.07, breathHz: 0.04, gain: 0.065, stereo: 0.9)
        case "tokyo_rain", "rain_window":
            return ProceduralCharacter(toneHz: 220, toneMix: 0.02, noiseMix: 0.72, lfoHz: 0.55, lfoDepth: 0.03, breathHz: 0.11, gain: 0.06, stereo: 0.88)
        case "night_cafe":
            return ProceduralCharacter(toneHz: 148, toneMix: 0.09, noiseMix: 0.4, lfoHz: 0.22, lfoDepth: 0.04, breathHz: 0.06, gain: 0.055, stereo: 0.93)
        case "minka_library":
            return ProceduralCharacter(toneHz: 180, toneMix: 0.05, noiseMix: 0.28, lfoHz: 0.09, lfoDepth: 0.02, breathHz: 0.03, gain: 0.045, stereo: 0.96)
        case "kyoto_bamboo":
            return ProceduralCharacter(toneHz: 260, toneMix: 0.07, noiseMix: 0.32, lfoHz: 0.28, lfoDepth: 0.05, breathHz: 0.07, gain: 0.05, stereo: 0.91)
        case "temple_bell":
            return ProceduralCharacter(toneHz: 196, toneMix: 0.16, noiseMix: 0.18, lfoHz: 0.07, lfoDepth: 0.08, breathHz: 0.02, gain: 0.05, stereo: 0.95)
        case "night_forest":
            return ProceduralCharacter(toneHz: 130, toneMix: 0.04, noiseMix: 0.38, lfoHz: 0.15, lfoDepth: 0.06, breathHz: 0.035, gain: 0.048, stereo: 0.87)
        default:
            return ProceduralCharacter(toneHz: 120, toneMix: 0.05, noiseMix: 0.45, lfoHz: 0.2, lfoDepth: 0.03, breathHz: 0.05, gain: 0.055, stereo: 0.94)
        }
    }

    private func fadeAsync(to volume: Float, on node: AVAudioMixerNode, duration: TimeInterval) async {
        let steps = 60
        let start = node.outputVolume
        let stepTime = duration / Double(max(steps, 1))
        for i in 1...steps {
            if Task.isCancelled { return }
            let t = Float(i) / Float(steps)
            node.outputVolume = start + (volume - start) * t
            try? await Task.sleep(for: .seconds(stepTime))
        }
    }

    private func observeRouteChanges() {
        routeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleRouteChange(notification)
            }
        }
    }

    private func observeInterruptions() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleInterruption(notification)
            }
        }
    }

    private func handleRouteChange(_ notification: Notification) {
        refreshHeadphones()
        guard let info = notification.userInfo,
              let raw = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: raw) else { return }
        switch reason {
        case .oldDeviceUnavailable:
            if isPlaying { stop(fadeDuration: 0.5) }
        case .newDeviceAvailable:
            if headphonesConnected {
                NotificationCenter.default.post(name: .headphonesConnected, object: nil)
            }
        default:
            break
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let raw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
        if type == .ended {
            let options = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            if AVAudioSession.InterruptionOptions(rawValue: options).contains(.shouldResume) {
                startEngineIfNeeded()
                if isPlaying { primaryPlayer.play() }
            }
        }
    }

    private func refreshHeadphones() {
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        headphonesConnected = outputs.contains {
            [.headphones, .bluetoothA2DP, .bluetoothHFP, .bluetoothLE].contains($0.portType)
        }
    }

    // MARK: - Remote Media Center & Now Playing

    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            if !self.isPlaying {
                if let sound = self.primarySound ?? Sound.library.first {
                    self.play(sound: sound)
                }
            }
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            if self.isPlaying {
                self.stop()
            }
            return .success
        }

        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.toggle()
            return .success
        }
    }

    private func updateNowPlayingInfo() {
        var info = [String: Any]()
        if let sound = primarySound {
            info[MPMediaItemPropertyTitle] = sound.title
            info[MPMediaItemPropertyArtist] = "Stillway • " + sound.subtitle
        } else {
            info[MPMediaItemPropertyTitle] = "Stillway Ambient"
            info[MPMediaItemPropertyArtist] = "Stillway"
        }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0.0
        info[MPMediaItemPropertyPlaybackDuration] = sessionDuration > 0 ? sessionDuration : 1800.0
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func clearNowPlayingInfo() {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // MARK: - Session Completion Bell Chime & Tranquil Haptic

    private func playCompletionChime() {
        DispatchQueue.main.async {
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.success)
        }
        if let chimeURL = Bundle.main.url(forResource: "temple_bell", withExtension: "m4a") ?? Bundle.main.url(forResource: "gong_bath", withExtension: "m4a") {
            do {
                let chimeFile = try AVAudioFile(forReading: chimeURL)
                let chimePlayer = AVAudioPlayerNode()
                self.engine.attach(chimePlayer)
                self.engine.connect(chimePlayer, to: self.masterMixer, format: chimeFile.processingFormat)
                chimePlayer.scheduleFile(chimeFile, at: nil)
                chimePlayer.play()
            } catch {
                // Graceful ignore
            }
        }
    }
}

extension Notification.Name {
    static let headphonesConnected = Notification.Name("stillway.headphonesConnected")
    static let contextDidChange = Notification.Name("stillway.contextDidChange")
    static let autoSessionTriggered = Notification.Name("stillway.autoSessionTriggered")
    static let placeNeedsLabel = Notification.Name("stillway.placeNeedsLabel")
    static let sleepPromptNeeded = Notification.Name("stillway.sleepPromptNeeded")
    static let stillwayHeadphonesChanged = Notification.Name("stillwayHeadphonesChanged")
}

private struct SplitMix64 {
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    mutating func nextNormalized() -> Double {
        Double(next() >> 11) / Double(1 << 53) * 2 - 1
    }
}
