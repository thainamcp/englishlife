import CoreImage
import Foundation
import Vision

/// Produces one avatar image from the preferences chosen during character setup.
struct AvatarGenerationAPIClient {
  private let apiClient: OpenAIAPIClient

  init(apiClient: OpenAIAPIClient = .shared) {
    self.apiClient = apiClient
  }

  func generate(
    name: String,
    gender: String,
    vibe: String,
    hair: String,
    accessory: String
  ) async throws -> Data {
    let generatedImage = try await generateImage(body: [
      "model": OpenAIModel.textToImage,
      "prompt": prompt(
        name: name,
        gender: gender,
        vibe: vibe,
        hair: hair,
        accessory: accessory
      ),
      "n": 1,
      "size": "1024x1536",
      "quality": "low",
      "output_format": "png",
      // `gpt-image-2` currently supports opaque output only.
      "background": "opaque",
    ])
    // gpt-image-2 currently returns an opaque image. On iOS 17+, Vision lifts
    // the single generated character into a PNG with an alpha channel. If the
    // subject cannot be detected, preserving the original is safer than losing
    // a usable avatar.
    return AvatarForegroundExtractor.transparentPNG(from: generatedImage) ?? generatedImage
  }

  func generateLocation(named name: String, description: String) async throws -> Data {
    try await generateImage(body: [
      "model": OpenAIModel.textToImage,
      "prompt": """
      Create a cinematic but cozy illustrated background for an English-learning adventure game.
      Location: \(name). \(description).
      No people, no characters, no text, no letters, no logos, no watermark. Leave open visual space in the lower center for a standing character. Portrait mobile-game composition, polished storybook art, warm natural lighting.
      """,
      "n": 1,
      "size": "1024x1024",
      "quality": "low",
      "output_format": "png",
      "background": "opaque",
    ])
  }

  private func generateImage(body: [String: Any]) async throws -> Data {
    let payload: AvatarGenerationPayload = try await apiClient.post(
      .imageGenerations,
      flow: .avatarGeneration,
      body: body
    )
    guard let encodedImage = payload.data.first?.b64JSON,
      let imageData = Data(base64Encoded: encodedImage)
    else {
      throw OpenAIAPIClientError.invalidResponse
    }
    return imageData
  }

  private func prompt(
    name: String,
    gender: String,
    vibe: String,
    hair: String,
    accessory: String
  ) -> String {
    """
    Create a polished, friendly illustrated character portrait for an English-learning adventure app.
    Subject: an adult \(gender) named \(name), with a \(vibe.lowercased()) vibe, \(hair.lowercased()) hair, and \(accessory.lowercased()).
    Full-body standing character, looking at the viewer, warm approachable expression, clean modern storybook illustration. Place exactly one person on a plain, high-contrast light studio backdrop with no props, scenery, shadows, or other objects. Keep the complete body inside the frame with clear edges for foreground extraction. Vivid but tasteful colors, rounded shapes, no text, no letters, no logos, no watermark.
    """
  }
}

/// Native iOS foreground extraction for avatar art. The Vision result retains
/// the detected character while making every other pixel transparent.
private enum AvatarForegroundExtractor {
  static func transparentPNG(from imageData: Data) -> Data? {
    guard #available(iOS 17.0, *), let sourceImage = CIImage(data: imageData) else {
      return nil
    }

    do {
      let request = VNGenerateForegroundInstanceMaskRequest()
      let handler = VNImageRequestHandler(ciImage: sourceImage, options: [:])
      try handler.perform([request])
      guard let observation = request.results?.first else { return nil }

      let maskedPixelBuffer = try observation.generateMaskedImage(
        ofInstances: observation.allInstances,
        from: handler,
        croppedToInstancesExtent: false
      )
      let maskedImage = CIImage(cvPixelBuffer: maskedPixelBuffer)
      return CIContext().pngRepresentation(
        of: maskedImage,
        format: .RGBA8,
        colorSpace: CGColorSpaceCreateDeviceRGB(),
        options: [:]
      )
    } catch {
      return nil
    }
  }
}

private struct AvatarGenerationPayload: Decodable {
  struct ImageData: Decodable {
    let b64JSON: String?

    enum CodingKeys: String, CodingKey { case b64JSON = "b64_json" }
  }

  let data: [ImageData]
}
