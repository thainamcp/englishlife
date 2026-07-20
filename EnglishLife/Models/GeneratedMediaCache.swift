import Foundation

/// Disk cache for generated character portraits and location backgrounds.
final class GeneratedMediaCache {
  static let shared = GeneratedMediaCache()

  private let directory: URL

  init(fileManager: FileManager = .default) {
    let root =
      fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
      ?? fileManager.temporaryDirectory
    directory = root.appending(path: "English/GeneratedMedia", directoryHint: .isDirectory)
    try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
  }

  func imageData(for key: String) -> Data? {
    try? Data(contentsOf: fileURL(for: key))
  }

  func save(_ data: Data, for key: String) {
    try? data.write(to: fileURL(for: key), options: .atomic)
  }

  private func fileURL(for key: String) -> URL {
    let safeKey = key.lowercased().map { character in
      character.isLetter || character.isNumber ? String(character) : "-"
    }.joined()
    return directory.appending(path: safeKey + ".png")
  }
}
