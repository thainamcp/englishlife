import AVFoundation
import SwiftUI

enum VoiceConversationState: Equatable {
  case idle, requestingPermission, listening, speaking, unavailable

  var label: String {
    switch self {
    case .idle: "Tap to start speaking"
    case .requestingPermission: "Requesting microphone access…"
    case .listening: "Listening… speak naturally"
    case .speaking: "Your character is speaking…"
    case .unavailable: "Microphone access is required"
    }
  }
}

/// UI state for an OpenAI Realtime voice session. The actual WebRTC session must be
/// established with a short-lived client secret returned by the app's backend.
@MainActor
final class VoiceConversationViewModel: ObservableObject {
  @Published private(set) var state: VoiceConversationState = .idle
  let modelName = OpenAIModel.realtimeVoice
  private var wantsToListen = false

  func toggleListening() async {
    if state == .listening { stopListening() } else { await startListening() }
  }

  func startListening() async {
    guard state != .listening else { return }
    wantsToListen = true
    state = .requestingPermission
    let granted = await withCheckedContinuation { continuation in
      AVAudioApplication.requestRecordPermission { continuation.resume(returning: $0) }
    }
    guard wantsToListen else {
      state = .idle
      return
    }
    state = granted ? .listening : .unavailable
  }

  func stopListening() {
    wantsToListen = false
    if state != .unavailable { state = .idle }
  }

  func stop() { stopListening() }
}
