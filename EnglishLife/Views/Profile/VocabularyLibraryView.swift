import SwiftUI

struct VocabularyLibraryView: View {
  @EnvironmentObject private var state: AppViewModel
  @Environment(\.dismiss) private var dismiss
  @State private var isEditing = false
  @State private var selectedIDs = Set<String>()
  @State private var showsDeleteConfirmation = false

  private let columns = [
    GridItem(.flexible(), spacing: 10),
    GridItem(.flexible(), spacing: 10),
  ]

  var body: some View {
    ZStack {
      ThemeApp.Colors.canvas.ignoresSafeArea()

      VStack(spacing: 0) {
        header
          .padding(.horizontal, 20)
          .padding(.top, 2)
          .padding(.bottom, 18)

        ScrollView(showsIndicators: false) {
          if state.vocabulary.isEmpty {
            emptyState
              .padding(.top, 116)
          } else {
            LazyVGrid(columns: columns, spacing: 10) {
              ForEach(state.vocabulary) { word in
                vocabularyCell(word)
              }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
          }
        }
      }

      if showsDeleteConfirmation { deleteConfirmation }
    }
    .foregroundStyle(ThemeApp.Colors.textPrimary)
    .navigationBarBackButtonHidden(true)
    .toolbar(.hidden, for: .navigationBar)
  }

  private var header: some View {
    HStack {
      Button {
        if isEditing {
          isEditing = false
          selectedIDs.removeAll()
        } else {
          dismiss()
        }
      } label: {
        Image(systemName: isEditing ? "xmark" : "chevron.left")
          .font(.system(size: 17, weight: .bold))
          .frame(width: 34, height: 34)
          .background(Color(hex: "#F48B8A"), in: Circle())
          .overlay(Circle().stroke(ThemeApp.Colors.border, lineWidth: 1.5))
      }
      .buttonStyle(.plain)

      Spacer()

      Text("Vocabulary Library")
        .font(ThemeApp.Fonts.ctaButton(size: 20))

      Spacer()

      Button {
        if isEditing {
          guard !selectedIDs.isEmpty else { return }
          showsDeleteConfirmation = true
        } else {
          isEditing = true
        }
      } label: {
        Image(systemName: isEditing ? "trash.fill" : "pencil")
          .font(.system(size: 15, weight: .bold))
          .foregroundStyle(
            isEditing && selectedIDs.isEmpty ? ThemeApp.Colors.textSecondary : .white
          )
          .frame(width: 34, height: 34)
          .background(
            isEditing && selectedIDs.isEmpty
              ? ThemeApp.Colors.surface.opacity(0.9) : Color(hex: "#F48B8A"),
            in: Circle()
          )
          .overlay(Circle().stroke(ThemeApp.Colors.border, lineWidth: 1.5))
      }
      .buttonStyle(.plain)
    }
  }

  private func vocabularyCell(_ word: VocabularyWord) -> some View {
    let isSelected = selectedIDs.contains(word.id)
    return Group {
      if isEditing {
        Button {
          if isSelected {
            selectedIDs.remove(word.id)
          } else {
            selectedIDs.insert(word.id)
          }
        } label: {
          vocabularyCellLabel(word, isSelected: isSelected)
        }
        .buttonStyle(.plain)
      } else {
        NavigationLink {
          VocabularyWordDetailView(wordID: word.id)
            .environmentObject(state)
        } label: {
          vocabularyCellLabel(word, isSelected: false)
        }
        .buttonStyle(.plain)
      }
    }
  }

  private func vocabularyCellLabel(_ word: VocabularyWord, isSelected: Bool) -> some View {
    HStack(spacing: 8) {
      Text(word.word)
        .font(ThemeApp.Fonts.body2Text(size: 14))
        .lineLimit(1)
        .frame(maxWidth: .infinity)
      if isEditing, isSelected {
        Image(systemName: "checkmark")
          .font(.system(size: 12, weight: .black))
      }
    }
    .foregroundStyle(ThemeApp.Colors.textPrimary)
    .frame(maxWidth: .infinity)
    .frame(height: 64)
    .padding(.horizontal, 8)
    .background(
      isSelected ? Color(hex: "#F48B8A") : ThemeApp.Colors.surface,
      in: RoundedRectangle(cornerRadius: 32)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 32)
        .strokeBorder(ThemeApp.Colors.border, lineWidth: 1.5)
    )
  }

  private var emptyState: some View {
    VStack(spacing: 12) {
      Image(systemName: "text.book.closed.fill")
        .font(.system(size: 52, weight: .bold))
        .foregroundStyle(ThemeApp.Colors.textSecondary)
      Text("Your vocabulary library is waiting")
        .font(ThemeApp.Fonts.ctaButton(size: 19))
      Text("Start a study path to collect useful English words here.")
        .font(ThemeApp.Fonts.body2Text())
        .foregroundStyle(ThemeApp.Colors.textSecondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 42)
    }
  }

  private var deleteConfirmation: some View {
    ZStack {
      Color.black.opacity(0.28).ignoresSafeArea()
      VStack(spacing: 16) {
        Text("Delete selected words?")
          .font(ThemeApp.Fonts.ctaButton(size: 19))
        Text("The selected vocabulary will be removed from your library.")
          .font(ThemeApp.Fonts.body2Text(size: 14))
          .foregroundStyle(ThemeApp.Colors.textSecondary)
          .multilineTextAlignment(.center)
        HStack(spacing: 12) {
          Button("Cancel") { showsDeleteConfirmation = false }
            .font(ThemeApp.Fonts.ctaButton(size: 15))
            .foregroundStyle(ThemeApp.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .overlay(Capsule().stroke(ThemeApp.Colors.border, lineWidth: 1.5))

          Button("Delete") {
            state.deleteVocabulary(ids: selectedIDs)
            selectedIDs.removeAll()
            isEditing = false
            showsDeleteConfirmation = false
          }
          .font(ThemeApp.Fonts.ctaButton(size: 15))
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 42)
          .background(Color(hex: "#EF4B4D"), in: Capsule())
          .overlay(Capsule().stroke(ThemeApp.Colors.border, lineWidth: 1.5))
        }
      }
      .padding(24)
      .frame(maxWidth: 320)
      .background(ThemeApp.Colors.surface, in: RoundedRectangle(cornerRadius: 24))
      .overlay(RoundedRectangle(cornerRadius: 24).stroke(ThemeApp.Colors.border, lineWidth: 1.5))
      .padding(.horizontal, 30)
    }
  }
}

struct VocabularyWordDetailView: View {
  @EnvironmentObject private var state: AppViewModel
  @Environment(\.dismiss) private var dismiss
  let wordID: String
  @State private var isGenerating = false
  @State private var errorMessage: String?
  @State private var showsDeleteConfirmation = false
  @State private var generationTask: Task<Void, Never>?
  private let client = VocabularyAPIClient()

  private var word: VocabularyWord? {
    state.vocabulary.first { $0.id == wordID }
  }

  var body: some View {
    ZStack {
      ThemeApp.Colors.canvas.ignoresSafeArea()
      VStack(spacing: 0) {
        header
          .padding(.horizontal, 20)
          .padding(.top, 2)
          .padding(.bottom, 20)

        if isGenerating {
          Spacer(minLength: 0)
          generatingState
          Spacer(minLength: 0)
          loadingGenerateButton
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        } else if let word {
          VStack(spacing: 16) {
            wordCard(word)
            examplesCard(word)
            Spacer(minLength: 0)
            generateButton(word)
          }
          .padding(.horizontal, 20)
          .padding(.bottom, 30)
        } else {
          ContentUnavailableView("Word unavailable", systemImage: "text.book.closed")
          Spacer()
        }
      }

      if showsDeleteConfirmation {
        deleteConfirmation
      }
    }
    .foregroundStyle(ThemeApp.Colors.textPrimary)
    .navigationBarBackButtonHidden(true)
    .toolbar(.hidden, for: .navigationBar)
  }

  private var header: some View {
    HStack {
      Button {
        dismiss()
      } label: {
        Image(systemName: "chevron.left")
          .font(.system(size: 17, weight: .bold))
          .frame(width: 34, height: 34)
          .background(Color(hex: "#F48B8A"), in: Circle())
          .overlay(Circle().stroke(ThemeApp.Colors.border, lineWidth: 1.5))
      }
      .buttonStyle(.plain)
      Spacer()
      Text("Word Detail")
        .font(ThemeApp.Fonts.ctaButton(size: 20))
      Spacer()
      Button {
        showsDeleteConfirmation = true
      } label: {
        Image(systemName: "trash.fill")
          .font(.system(size: 15, weight: .bold))
          .foregroundStyle(.white)
          .frame(width: 34, height: 34)
          .background(Color(hex: "#F48B8A"), in: Circle())
          .overlay(Circle().stroke(ThemeApp.Colors.border, lineWidth: 1.5))
      }
      .buttonStyle(.plain)
    }
  }

  private func wordCard(_ word: VocabularyWord) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(word.word)
        .font(ThemeApp.Fonts.gameTitle(size: 26))
        .frame(maxWidth: .infinity, alignment: .center)
      Divider().overlay(ThemeApp.Colors.border.opacity(0.68))

      if let detail = word.detail {
        HStack(spacing: 8) {
          Text(detail.partOfSpeech.uppercased())
            .font(ThemeApp.Fonts.ctaButton(size: 12))
            .foregroundStyle(ThemeApp.Colors.primary)
          Text(detail.phonetic)
            .font(ThemeApp.Fonts.body2Text(size: 13))
            .foregroundStyle(ThemeApp.Colors.textSecondary)
        }
        Text(detail.meaningOnly)
          .font(ThemeApp.Fonts.bodyText(size: 16))
      } else {
        Text("Generate AI examples to understand how this word is used in real conversations.")
          .font(ThemeApp.Fonts.body2Text(size: 14))
          .foregroundStyle(ThemeApp.Colors.textSecondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(18)
    .background(ThemeApp.Colors.surface, in: RoundedRectangle(cornerRadius: 20))
    .overlay(RoundedRectangle(cornerRadius: 20).stroke(ThemeApp.Colors.border, lineWidth: 1.5))
  }

  private func examplesCard(_ word: VocabularyWord) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("AI EXAMPLES")
        .font(ThemeApp.Fonts.ctaButton(size: 12))
      if let detail = word.detail {
        VStack(spacing: 9) {
          ForEach(Array(detail.examples.enumerated()), id: \.offset) { index, example in
            HStack(alignment: .top, spacing: 8) {
              Text("\(index + 1)")
                .font(ThemeApp.Fonts.ctaButton(size: 11))
                .foregroundStyle(ThemeApp.Colors.textPrimary)
                .frame(width: 20, height: 20)
                .background(Color(hex: "#FFE900"), in: Circle())
              Text(example)
                .font(ThemeApp.Fonts.body2Text(size: 14))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(10)
            .background(Color.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ThemeApp.Colors.border.opacity(0.7)))
          }
        }
      } else {
        Text(
          errorMessage ?? "No examples yet. Tap Generate to create example sentences for this word."
        )
        .font(ThemeApp.Fonts.body2Text(size: 14))
        .foregroundStyle(ThemeApp.Colors.textSecondary)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .center)
        .multilineTextAlignment(.center)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(18)
    .background(ThemeApp.Colors.surface, in: RoundedRectangle(cornerRadius: 20))
    .overlay(
      RoundedRectangle(cornerRadius: 20)
        .stroke(ThemeApp.Colors.border, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
    )
  }

  private func generateButton(_ word: VocabularyWord) -> some View {
    Button {
      beginGeneratingDetail(for: word)
    } label: {
      HStack(spacing: 8) {
        if isGenerating { ProgressView().tint(.white) }
        Image(systemName: "sparkles")
        Text(word.detail == nil ? "Generate" : "Generate New Examples")
      }
      .font(ThemeApp.Fonts.ctaButton(size: 16))
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity)
      .frame(height: 60)
      .background(ThemeApp.Colors.primary.opacity(isGenerating ? 0.48 : 1), in: Capsule())
      .overlay(Capsule().stroke(ThemeApp.Colors.border, lineWidth: 1.5))
    }
    .buttonStyle(.plain)
    .disabled(isGenerating)
  }

  private var generatingState: some View {
    VStack(spacing: 10) {
      ProgressView()
        .tint(ThemeApp.Colors.textSecondary)
        .scaleEffect(1.18)
        .padding(.bottom, 8)

      Text("Generating examples…")
        .font(ThemeApp.Fonts.ctaButton(size: 17))
        .foregroundStyle(ThemeApp.Colors.textPrimary)

      Text("AI is crafting contextual sentences")
        .font(ThemeApp.Fonts.body2Text(size: 14))
        .foregroundStyle(ThemeApp.Colors.textSecondary)

      Button("Cancel Request") {
        cancelGeneration()
      }
      .font(ThemeApp.Fonts.body2Text(size: 14))
      .foregroundStyle(ThemeApp.Colors.textPrimary)
      .padding(.horizontal, 22)
      .frame(height: 34)
      .overlay(Capsule().stroke(ThemeApp.Colors.border, lineWidth: 1.25))
      .buttonStyle(.plain)
      .padding(.top, 24)
    }
    .frame(maxWidth: .infinity)
  }

  private var loadingGenerateButton: some View {
    HStack(spacing: 8) {
      Image(systemName: "sparkles")
      Text("Generate")
    }
    .font(ThemeApp.Fonts.ctaButton(size: 16))
    .foregroundStyle(ThemeApp.Colors.textSecondary)
    .frame(maxWidth: .infinity)
    .frame(height: 60)
    .overlay(
      Capsule()
        .stroke(
          ThemeApp.Colors.textSecondary.opacity(0.9),
          style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])
        )
    )
  }

  private var deleteConfirmation: some View {
    ZStack {
      Color.black.opacity(0.28).ignoresSafeArea()

      VStack(spacing: 16) {
        Text("Delete this word?")
          .font(ThemeApp.Fonts.ctaButton(size: 19))
        Text("This vocabulary word and its generated examples will be removed from your library.")
          .font(ThemeApp.Fonts.body2Text(size: 14))
          .foregroundStyle(ThemeApp.Colors.textSecondary)
          .multilineTextAlignment(.center)

        HStack(spacing: 12) {
          Button("Cancel") {
            showsDeleteConfirmation = false
          }
          .font(ThemeApp.Fonts.ctaButton(size: 15))
          .foregroundStyle(ThemeApp.Colors.textPrimary)
          .frame(maxWidth: .infinity)
          .frame(height: 42)
          .overlay(Capsule().stroke(ThemeApp.Colors.border, lineWidth: 1.5))

          Button("Delete") {
            state.deleteVocabulary(ids: [wordID])
            showsDeleteConfirmation = false
            dismiss()
          }
          .font(ThemeApp.Fonts.ctaButton(size: 15))
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 42)
          .background(Color(hex: "#EF4B4D"), in: Capsule())
          .overlay(Capsule().stroke(ThemeApp.Colors.border, lineWidth: 1.5))
        }
      }
      .padding(24)
      .frame(maxWidth: 320)
      .background(ThemeApp.Colors.surface, in: RoundedRectangle(cornerRadius: 24))
      .overlay(RoundedRectangle(cornerRadius: 24).stroke(ThemeApp.Colors.border, lineWidth: 1.5))
      .padding(.horizontal, 30)
    }
  }

  private func beginGeneratingDetail(for word: VocabularyWord) {
    generationTask?.cancel()
    generationTask = Task {
      await generateDetail(for: word)
    }
  }

  private func cancelGeneration() {
    generationTask?.cancel()
    generationTask = nil
    isGenerating = false
    errorMessage = nil
  }

  private func generateDetail(for word: VocabularyWord) async {
    guard !isGenerating, !Task.isCancelled else { return }
    isGenerating = true
    errorMessage = nil
    defer {
      isGenerating = false
      generationTask = nil
    }
    do {
      let detail = try await client.generateDetail(for: word.word, learnerLevel: state.level)
      guard !Task.isCancelled else { return }
      state.saveVocabularyDetail(detail, for: word.id)
    } catch is CancellationError {
      return
    } catch {
      guard !Task.isCancelled else { return }
      errorMessage = error.localizedDescription
    }
  }
}
