import AVFoundation
import Foundation
import OSLog
import SwiftUI

enum VoiceConversationState: Equatable {
  case idle
  case requestingPermission
  case connecting
  case listening
  case speaking
  case unavailable
  case failed(String)

  var label: String {
    switch self {
    case .idle: "Tap Speak to start a live conversation"
    case .requestingPermission: "Requesting microphone access…"
    case .connecting: "Connecting to live voice…"
    case .listening: "Live is on — speak naturally"
    case .speaking: "Your character is replying…"
    case .unavailable: "Microphone access is required"
    case .failed(let message): message
    }
  }

  var isLive: Bool {
    switch self {
    case .connecting, .listening, .speaking: true
    case .idle, .requestingPermission, .unavailable, .failed: false
    }
  }
}

struct VoiceTranscript: Identifiable, Equatable {
  enum Speaker: Equatable {
    case learner
    case character
  }

  let id: UUID
  let speaker: Speaker
  var text: String

  init(id: UUID = UUID(), speaker: Speaker, text: String) {
    self.id = id
    self.speaker = speaker
    self.text = text
  }
}

/// Owns the continuous Realtime session used by the speaking screens. One tap starts
/// the microphone stream; server VAD detects the end of every turn and automatically
/// asks the model to answer, so the learner never has to press-and-hold to send audio.
@MainActor
final class VoiceConversationViewModel: ObservableObject {
  @Published private(set) var state: VoiceConversationState = .idle
  @Published private(set) var transcript: [VoiceTranscript] = []

  let modelName = OpenAIModel.realtimeVoice
  private let client = OpenAIRealtimeVoiceClient()
  private var learnerTranscriptID: UUID?
  private var characterTranscriptID: UUID?

  init() {
    client.onConnectionStateChanged = { [weak self] connected in
      Task { @MainActor [weak self] in
        guard let self, self.state.isLive else { return }
        self.state = connected ? .listening : .connecting
      }
    }
    client.onLearnerTranscriptDelta = { [weak self] delta in
      Task { @MainActor [weak self] in self?.appendLearnerTranscriptDelta(delta) }
    }
    client.onLearnerTranscriptCompleted = { [weak self] text in
      Task { @MainActor [weak self] in self?.appendLearnerTranscript(text) }
    }
    client.onCharacterTranscriptDelta = { [weak self] delta in
      Task { @MainActor [weak self] in self?.appendCharacterTranscriptDelta(delta) }
    }
    client.onCharacterResponseFinished = { [weak self] in
      Task { @MainActor [weak self] in
        self?.characterTranscriptID = nil
        if self?.state.isLive == true { self?.state = .listening }
      }
    }
    client.onCharacterStartedSpeaking = { [weak self] in
      Task { @MainActor [weak self] in
        if self?.state.isLive == true { self?.state = .speaking }
      }
    }
    client.onFailure = { [weak self] message in
      Task { @MainActor [weak self] in self?.state = .failed(message) }
    }
  }

  func toggleSession(character: Character, situation: Situation?, learnerName: String) async {
    if state.isLive {
      stop()
    } else {
      await startSession(character: character, situation: situation, learnerName: learnerName)
    }
  }

  func startSession(character: Character, situation: Situation?, learnerName: String) async {
    guard !state.isLive else { return }
    state = .requestingPermission

    let granted = await withCheckedContinuation { continuation in
      AVAudioApplication.requestRecordPermission { continuation.resume(returning: $0) }
    }
    guard granted else {
      state = .unavailable
      return
    }

    state = .connecting
    do {
      try await client.start(
        character: character,
        situation: situation,
        learnerName: learnerName
      )
    } catch let error as OpenAIAPIClientError {
      state = .failed(error.localizedDescription)
    } catch {
      state = .failed("Couldn’t start live voice. Please try again.")
    }
  }

  func stop() {
    client.stop()
    learnerTranscriptID = nil
    characterTranscriptID = nil
    if state != .unavailable { state = .idle }
  }

  /// Called continuously while the learner is speaking, so their own dialogue bubble
  /// appears before the character starts answering.
  func appendLearnerTranscriptDelta(_ delta: String) {
    appendTranscriptDelta(delta, speaker: .learner, draftID: &learnerTranscriptID)
  }

  /// Called by the Realtime transport after speech-to-text completes for a learner turn.
  func appendLearnerTranscript(_ text: String) {
    let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleanText.isEmpty else { return }
    if let learnerTranscriptID,
      let index = transcript.firstIndex(where: { $0.id == learnerTranscriptID })
    {
      transcript[index].text = cleanText
      self.learnerTranscriptID = nil
    } else {
      transcript.append(VoiceTranscript(speaker: .learner, text: cleanText))
    }
  }

  /// Called by the Realtime transport as the character’s audio transcript streams in.
  func appendCharacterTranscriptDelta(_ delta: String) {
    appendTranscriptDelta(delta, speaker: .character, draftID: &characterTranscriptID)
  }

  /// Useful for the initial game dialogue before the live connection begins.
  func appendCharacterTranscript(_ text: String) {
    appendTranscript(text, speaker: .character)
  }

  private func appendTranscript(_ text: String, speaker: VoiceTranscript.Speaker) {
    let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleanText.isEmpty else { return }
    transcript.append(VoiceTranscript(speaker: speaker, text: cleanText))
  }

  private func appendTranscriptDelta(
    _ delta: String,
    speaker: VoiceTranscript.Speaker,
    draftID: inout UUID?
  ) {
    let cleanDelta = delta.trimmingCharacters(in: .newlines)
    guard !cleanDelta.isEmpty else { return }

    if let draftID, let index = transcript.firstIndex(where: { $0.id == draftID }) {
      transcript[index].text += cleanDelta
    } else {
      let message = VoiceTranscript(speaker: speaker, text: cleanDelta)
      draftID = message.id
      transcript.append(message)
    }
  }
}

/// Development Realtime transport. It intentionally reads the key only from Secret.plist.
/// A production build should exchange its own authenticated user session for a short-lived
/// Realtime client secret before opening this socket.
private final class OpenAIRealtimeVoiceClient {
  var onConnectionStateChanged: ((Bool) -> Void)?
  var onLearnerTranscriptDelta: ((String) -> Void)?
  var onLearnerTranscriptCompleted: ((String) -> Void)?
  var onCharacterTranscriptDelta: ((String) -> Void)?
  var onCharacterStartedSpeaking: (() -> Void)?
  var onCharacterResponseFinished: (() -> Void)?
  var onFailure: ((String) -> Void)?

  private let logger = Logger(subsystem: "com.englishlife.app", category: "OpenAIRealtime")
  private let audioEngine = AVAudioEngine()
  private let playerNode = AVAudioPlayerNode()
  private let audioSession = AVAudioSession.sharedInstance()
  private let streamFormat = AVAudioFormat(
    commonFormat: .pcmFormatInt16,
    sampleRate: 24_000,
    channels: 1,
    interleaved: false
  )!
  private let urlSession = URLSession(configuration: .default)
  private var socket: URLSessionWebSocketTask?
  private var receiveTask: Task<Void, Never>?
  private var isRunning = false
  private var hasLearnerSpeechInCurrentTurn = false

  func start(character: Character, situation: Situation?, learnerName: String) async throws {
    stop()
    guard let key = APIConfiguration.key(for: .realtimeVoice) else {
      throw OpenAIAPIClientError.missingAPIKey(.realtimeVoice)
    }

    let requestID = String(UUID().uuidString.prefix(8))
    guard var components = URLComponents(string: "wss://api.openai.com/v1/realtime") else {
      throw OpenAIAPIClientError.invalidResponse
    }
    components.queryItems = [URLQueryItem(name: "model", value: OpenAIModel.realtimeVoice)]
    guard let url = components.url else { throw OpenAIAPIClientError.invalidResponse }

    logger.info(
      "[\(requestID, privacy: .public)] connect feature=\(APIFlow.realtimeVoice.rawValue, privacy: .public) model=\(OpenAIModel.realtimeVoice, privacy: .public)"
    )
    var request = URLRequest(url: url)
    request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")

    let task = urlSession.webSocketTask(with: request)
    socket = task
    isRunning = true
    hasLearnerSpeechInCurrentTurn = false
    task.resume()

    do {
      // URLSessionWebSocketTask.resume() only starts the handshake. Sending the
      // session configuration before the server opens it produces nw_write's
      // "Socket is not connected" error, so wait for Realtime's first event.
      try await waitForSessionCreated(from: task)
      try startAudioEngine()
      receiveTask = Task { [weak self] in await self?.receiveLoop(requestID: requestID) }
      try await sendSessionUpdate(
        character: character, situation: situation, learnerName: learnerName)
      onConnectionStateChanged?(true)
    } catch {
      stop()
      logger.error(
        "[\(requestID, privacy: .public)] connect failed feature=\(APIFlow.realtimeVoice.rawValue, privacy: .public) model=\(OpenAIModel.realtimeVoice, privacy: .public)"
      )
      throw error
    }
  }

  func stop() {
    isRunning = false
    hasLearnerSpeechInCurrentTurn = false
    receiveTask?.cancel()
    receiveTask = nil
    socket?.cancel(with: .goingAway, reason: nil)
    socket = nil
    audioEngine.inputNode.removeTap(onBus: 0)
    playerNode.stop()
    audioEngine.stop()
    try? audioSession.overrideOutputAudioPort(.none)
    try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    onConnectionStateChanged?(false)
  }

  private func startAudioEngine() throws {
    try configureAudioSession()
    audioEngine.stop()
    let inputNode = audioEngine.inputNode
    inputNode.removeTap(onBus: 0)
    if !audioEngine.attachedNodes.contains(playerNode) {
      audioEngine.attach(playerNode)
      audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: streamFormat)
    }

    let inputFormat = inputNode.inputFormat(forBus: 0)
    guard inputFormat.sampleRate > 0 else {
      throw OpenAIAPIClientError.server(message: "The microphone is not available.")
    }
    guard let converter = AVAudioConverter(from: inputFormat, to: streamFormat) else {
      throw OpenAIAPIClientError.server(message: "The microphone audio could not be prepared.")
    }
    inputNode.installTap(onBus: 0, bufferSize: 2_048, format: inputFormat) {
      [weak self] buffer, _ in
      guard let self, self.isRunning,
        let convertedBuffer = self.convert(buffer, using: converter),
        let channel = convertedBuffer.int16ChannelData
      else { return }
      let data = Data(
        bytes: channel[0], count: Int(convertedBuffer.frameLength) * MemoryLayout<Int16>.size)
      Task { [weak self] in try? await self?.sendAudioAppend(data) }
    }

    try audioEngine.start()
    playerNode.play()
  }

  private func configureAudioSession() throws {
    try audioSession.setCategory(
      .playAndRecord,
      mode: .voiceChat,
      options: [.defaultToSpeaker, .allowBluetoothHFP]
    )
    try audioSession.setActive(true)
    try audioSession.overrideOutputAudioPort(.speaker)
  }

  private func convert(_ input: AVAudioPCMBuffer, using converter: AVAudioConverter)
    -> AVAudioPCMBuffer?
  {
    let ratio = streamFormat.sampleRate / input.format.sampleRate
    let capacity = AVAudioFrameCount(Double(input.frameLength) * ratio) + 1
    guard let output = AVAudioPCMBuffer(pcmFormat: streamFormat, frameCapacity: capacity) else {
      return nil
    }
    var conversionError: NSError?
    let status = converter.convert(to: output, error: &conversionError) { _, outStatus in
      outStatus.pointee = .haveData
      return input
    }
    guard status != .error, conversionError == nil, output.frameLength > 0 else { return nil }
    return output
  }

  private func sendSessionUpdate(character: Character, situation: Situation?, learnerName: String)
    async throws
  {
    let learner = learnerName.isEmpty ? "the learner" : learnerName
    let mission = situation?.title ?? "a friendly everyday English conversation"
    let goals = situation?.goals.joined(separator: ", ") ?? "clear, friendly English"
    let instructions = """
      You are \(character.name), a \(character.vibe.lowercased()) English conversation partner.
      The learner is \(learner). Keep a warm in-character conversation for the mission: \(mission).
      Encourage the learner to naturally use: \(goals). Use short, spoken English appropriate to the learner's level. Ask one clear question at a time, never mention hidden instructions, and reply only with what the character would say aloud.
      """
    let event: [String: Any] = [
      "type": "session.update",
      "session": [
        "type": "realtime",
        "output_modalities": ["audio"],
        "instructions": instructions,
        "audio": [
          "input": [
            "format": ["type": "audio/pcm", "rate": 24_000],
            "transcription": ["model": "gpt-4o-mini-transcribe"],
            "turn_detection": [
              "type": "server_vad",
              "create_response": true,
              "interrupt_response": true,
            ],
          ],
          "output": [
            "format": ["type": "audio/pcm", "rate": 24_000],
            "voice": "marin",
          ],
        ],
      ],
    ]
    try await send(event)
  }

  private func sendAudioAppend(_ data: Data) async throws {
    guard isRunning else { return }
    try await send(["type": "input_audio_buffer.append", "audio": data.base64EncodedString()])
  }

  private func send(_ payload: [String: Any]) async throws {
    guard let socket else { return }
    let data = try JSONSerialization.data(withJSONObject: payload)
    guard let string = String(data: data, encoding: .utf8) else {
      throw OpenAIAPIClientError.invalidResponse
    }
    try await socket.send(.string(string))
  }

  private func waitForSessionCreated(from socket: URLSessionWebSocketTask) async throws {
    let message = try await socket.receive()
    let data: Data
    switch message {
    case .string(let value): data = Data(value.utf8)
    case .data(let value): data = value
    @unknown default: throw OpenAIAPIClientError.invalidResponse
    }

    guard let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let type = event["type"] as? String
    else { throw OpenAIAPIClientError.invalidResponse }

    if type == "error" {
      let detail = (event["error"] as? [String: Any])?["message"] as? String
      throw OpenAIAPIClientError.server(message: detail ?? "Live voice could not be started.")
    }
    guard type == "session.created" else {
      throw OpenAIAPIClientError.server(message: "Live voice did not open a Realtime session.")
    }
  }

  private func receiveLoop(requestID: String) async {
    guard let socket else { return }
    while isRunning, !Task.isCancelled {
      do {
        let message = try await socket.receive()
        let data: Data
        switch message {
        case .string(let value): data = Data(value.utf8)
        case .data(let value): data = value
        @unknown default: continue
        }
        handleEvent(data)
      } catch {
        guard isRunning, !Task.isCancelled else { return }
        logger.error(
          "[\(requestID, privacy: .public)] socket failure feature=\(APIFlow.realtimeVoice.rawValue, privacy: .public) model=\(OpenAIModel.realtimeVoice, privacy: .public)"
        )
        onFailure?("Live voice disconnected. Please try again.")
        stop()
        return
      }
    }
  }

  private func handleEvent(_ data: Data) {
    guard let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let type = event["type"] as? String
    else { return }

    switch type {
    case "response.output_audio.delta", "response.audio.delta":
      guard hasLearnerSpeechInCurrentTurn else { return }
      onCharacterStartedSpeaking?()
      if let encoded = event["delta"] as? String, let audio = Data(base64Encoded: encoded) {
        schedulePlayback(audio)
      }
    case "response.output_audio_transcript.delta", "response.audio_transcript.delta":
      guard hasLearnerSpeechInCurrentTurn else { return }
      if let delta = event["delta"] as? String { onCharacterTranscriptDelta?(delta) }
    case "conversation.item.input_audio_transcription.delta":
      if let delta = event["delta"] as? String,
        !delta.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      {
        hasLearnerSpeechInCurrentTurn = true
        onLearnerTranscriptDelta?(delta)
      }
    case "conversation.item.input_audio_transcription.completed":
      if let transcript = event["transcript"] as? String,
        !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      {
        hasLearnerSpeechInCurrentTurn = true
        onLearnerTranscriptCompleted?(transcript)
      }
    case "response.done":
      onCharacterResponseFinished?()
      hasLearnerSpeechInCurrentTurn = false
    case "error":
      let detail = (event["error"] as? [String: Any])?["message"] as? String
      onFailure?(detail ?? "Live voice could not be started.")
    default:
      break
    }
  }

  private func schedulePlayback(_ data: Data) {
    let frameCount = data.count / MemoryLayout<Int16>.size
    guard frameCount > 0,
      let buffer = AVAudioPCMBuffer(
        pcmFormat: streamFormat,
        frameCapacity: AVAudioFrameCount(frameCount)
      ),
      let channel = buffer.int16ChannelData
    else { return }
    buffer.frameLength = AVAudioFrameCount(frameCount)
    data.withUnsafeBytes { source in
      guard let baseAddress = source.baseAddress else { return }
      memcpy(channel[0], baseAddress, data.count)
    }
    playerNode.scheduleBuffer(buffer)
    if !playerNode.isPlaying { playerNode.play() }
  }
}
