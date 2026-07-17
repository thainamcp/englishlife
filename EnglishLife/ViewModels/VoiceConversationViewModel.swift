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

  func toggleListening() async {
    guard state != .listening else {
      state = .idle
      return
    }
    state = .requestingPermission
    let granted = await withCheckedContinuation { continuation in
      AVAudioApplication.requestRecordPermission { continuation.resume(returning: $0) }
    }
    state = granted ? .listening : .unavailable
  }

  func stop() { state = .idle }
}
