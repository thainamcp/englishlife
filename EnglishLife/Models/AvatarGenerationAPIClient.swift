import CoreImage
import Foundation
import UIKit
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
    return Self.transparentAvatarPNG(from: generatedImage) ?? generatedImage
  }

  /// Converts the generated opaque portrait into a PNG with a transparent
  /// background. It is also used to migrate portraits cached by earlier app
  /// versions before they are rendered in a speaking scene.
  static func transparentAvatarPNG(from imageData: Data) -> Data? {
    AvatarForegroundExtractor.transparentPNG(from: imageData)
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

/// Native iOS foreground extraction for avatar art. Vision segmentation is
/// preferred; a solid studio backdrop gets an edge-connected color-key pass
/// when Vision cannot recognize an illustrated character.
private enum AvatarForegroundExtractor {
  private static let context = CIContext()

  static func transparentPNG(from imageData: Data) -> Data? {
    guard let uiImage = UIImage(data: imageData), let cgImage = uiImage.cgImage else { return nil }
    let sourceImage = CIImage(cgImage: cgImage)

    if let png = personSegmentationPNG(sourceImage: sourceImage, cgImage: cgImage),
      hasUsableTransparency(in: png)
    {
      return png
    }

    if #available(iOS 17.0, *),
      let png = foregroundInstancePNG(sourceImage: sourceImage, cgImage: cgImage),
      hasUsableTransparency(in: png)
    {
      return png
    }

    return edgeConnectedBackgroundPNG(from: cgImage)
  }

  @available(iOS 17.0, *)
  private static func foregroundInstancePNG(sourceImage: CIImage, cgImage: CGImage) -> Data? {
    let request = VNGenerateForegroundInstanceMaskRequest()
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    guard
      (try? handler.perform([request])) != nil,
      let observation = request.results?.first,
      let maskedPixelBuffer = try? observation.generateMaskedImage(
        ofInstances: observation.allInstances,
        from: handler,
        croppedToInstancesExtent: false
      )
    else {
      return nil
    }

    return pngData(for: CIImage(cvPixelBuffer: maskedPixelBuffer), extent: sourceImage.extent)
  }

  private static func personSegmentationPNG(sourceImage: CIImage, cgImage: CGImage) -> Data? {
    let request = VNGeneratePersonSegmentationRequest()
    request.qualityLevel = .accurate
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    guard
      (try? handler.perform([request])) != nil,
      let maskPixelBuffer = request.results?.first?.pixelBuffer
    else {
      return nil
    }

    let maskImage = CIImage(cvPixelBuffer: maskPixelBuffer)
    let scaleX = sourceImage.extent.width / maskImage.extent.width
    let scaleY = sourceImage.extent.height / maskImage.extent.height
    let scaledMask = maskImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
    let clearBackground = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0))
      .cropped(to: sourceImage.extent)
    let cutout = sourceImage.applyingFilter(
      "CIBlendWithMask",
      parameters: [
        kCIInputBackgroundImageKey: clearBackground,
        kCIInputMaskImageKey: scaledMask,
      ]
    )
    return pngData(for: cutout, extent: sourceImage.extent)
  }

  /// Removes a plain background only when it is connected to the image edge.
  /// This protects white clothing and other light details inside the character.
  private static func edgeConnectedBackgroundPNG(from cgImage: CGImage) -> Data? {
    let width = cgImage.width
    let height = cgImage.height
    guard width > 1, height > 1 else { return nil }

    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel
    let bitmapInfo =
      CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
    var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)
    guard
      let drawingContext = CGContext(
        data: &pixels,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: bitmapInfo
      )
    else {
      return nil
    }
    drawingContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

    let corners = [0, width - 1, (height - 1) * width, height * width - 1]
    let backgroundColor = corners.reduce(into: (red: 0, green: 0, blue: 0)) { color, pixel in
      let offset = pixel * bytesPerPixel
      color.red += Int(pixels[offset])
      color.green += Int(pixels[offset + 1])
      color.blue += Int(pixels[offset + 2])
    }
    let reference = (
      red: backgroundColor.red / corners.count,
      green: backgroundColor.green / corners.count,
      blue: backgroundColor.blue / corners.count
    )

    func isBackdrop(_ pixel: Int) -> Bool {
      let offset = pixel * bytesPerPixel
      let difference = max(
        abs(Int(pixels[offset]) - reference.red),
        abs(Int(pixels[offset + 1]) - reference.green),
        abs(Int(pixels[offset + 2]) - reference.blue)
      )
      return pixels[offset + 3] > 0 && difference < 64
    }

    var visited = [Bool](repeating: false, count: width * height)
    var queue: [Int] = []
    func enqueue(_ pixel: Int) {
      guard !visited[pixel], isBackdrop(pixel) else { return }
      visited[pixel] = true
      queue.append(pixel)
    }

    for x in 0..<width {
      enqueue(x)
      enqueue((height - 1) * width + x)
    }
    for y in 0..<height {
      enqueue(y * width)
      enqueue(y * width + width - 1)
    }

    var queueIndex = 0
    while queueIndex < queue.count {
      let pixel = queue[queueIndex]
      queueIndex += 1
      let offset = pixel * bytesPerPixel
      pixels[offset] = 0
      pixels[offset + 1] = 0
      pixels[offset + 2] = 0
      pixels[offset + 3] = 0

      let x = pixel % width
      let y = pixel / width
      if x > 0 { enqueue(pixel - 1) }
      if x < width - 1 { enqueue(pixel + 1) }
      if y > 0 { enqueue(pixel - width) }
      if y < height - 1 { enqueue(pixel + width) }
    }

    guard queue.count > width * height / 100 else { return nil }
    let data = Data(pixels)
    guard
      let provider = CGDataProvider(data: data as CFData),
      let cutout = CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: bytesPerRow,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
        provider: provider,
        decode: nil,
        shouldInterpolate: true,
        intent: .defaultIntent
      )
    else {
      return nil
    }
    return UIImage(cgImage: cutout).pngData()
  }

  private static func hasUsableTransparency(in imageData: Data) -> Bool {
    guard let image = UIImage(data: imageData), let cgImage = image.cgImage else { return false }
    let width = cgImage.width
    let height = cgImage.height
    let bytesPerRow = width * 4
    let bitmapInfo =
      CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
    var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)
    guard
      let drawingContext = CGContext(
        data: &pixels,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: bitmapInfo
      )
    else {
      return false
    }
    drawingContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

    var transparentPixels = 0
    var visiblePixels = 0
    for alphaOffset in stride(from: 3, to: pixels.count, by: 4) {
      if pixels[alphaOffset] < 250 { transparentPixels += 1 }
      if pixels[alphaOffset] > 25 { visiblePixels += 1 }
    }
    let pixelCount = width * height
    return transparentPixels > pixelCount / 100 && visiblePixels > pixelCount / 100
  }

  private static func pngData(for image: CIImage, extent: CGRect) -> Data? {
    context.pngRepresentation(
      of: image,
      format: .RGBA8,
      colorSpace: CGColorSpaceCreateDeviceRGB(),
      options: [:]
    )
  }
}

private struct AvatarGenerationPayload: Decodable {
  struct ImageData: Decodable {
    let b64JSON: String?

    enum CodingKeys: String, CodingKey { case b64JSON = "b64_json" }
  }

  let data: [ImageData]
}
