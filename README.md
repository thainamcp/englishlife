# English Life

**English Life** is a voice-first English-learning adventure for people starting a new life in an English-speaking town. Instead of studying disconnected word lists, learners move through a town, meet recurring characters, and complete practical spoken missions—from meeting a landlord to ordering coffee, joining a community, and handling essential services.

The experience is designed around one idea: **confidence grows when language is practiced in context.**

## What the learner experiences

1. **Onboarding** — enters a name and self-assessed English level.
2. **Personalized study path** — receives a five-chapter journey with ten sequential situations in each chapter.
3. **Mission setup** — opens a map node, receives an AI welcome and level-appropriate phrases, then customizes a recurring character.
4. **Live speaking scene** — talks naturally with the character in a generated location; no typing is required.
5. **Mission check and progress** — spoken phrases are matched against the mission keywords. Completing all targets unlocks the next situation.
6. **Character and vocabulary library** — revisits unlocked characters, tracks progress, and expands learned words into definitions and examples.

## Product decisions

- **A town, not a curriculum spreadsheet.** The move-to-a-new-town narrative gives every lesson a concrete reason to exist: housing, daily routines, community, work/study, and independent living.
- **Voice-first practice.** Situation mode deliberately centers a single Speak control and a game-style dialogue scene, so the learner practices producing English instead of composing chat messages.
- **Level changes the task—not just the label.** Beginner missions use short, concrete phrases; intermediate learners receive more natural exchanges; advanced learners get procedural, negotiation, and culturally nuanced situations.
- **Recurring characters and locations.** A character can reappear in a new setting and a location can host different characters. This makes the town feel coherent while avoiding unnecessary image generation.
- **Visible mastery.** The mission check updates from the learner's spoken transcript. Full completion awards XP, unlocks the next node, and preserves the journey for the next launch.

## Technical implementation

### SwiftUI architecture

The app uses **SwiftUI + MVVM**:

- `Views/` contains screen-level UI for onboarding, map, mission, character setup, speaking, profile, and vocabulary.
- `ViewModels/` owns stateful business logic: `AppViewModel`, `MapViewModel`, `NarrativeViewModel`, `CharacterSetupViewModel`, `SituationSceneViewModel`, and `VoiceConversationViewModel`.
- `Models/` contains domain models, JSON loading, persistence, OpenAI clients, prompt construction, and generated-media caching.
- `Data/App/` keeps the bundled chapter, situation, character, location, and scene-pattern JSON separate from presentation code.

```mermaid
flowchart LR
    A[Onboarding: name + level] --> B[AI study path]
    B --> C[Map: chapter + situation]
    C --> D[AI guide + mission keywords]
    D --> E[Character + scene generation/cache]
    E --> F[Realtime voice conversation]
    F --> G[Transcript keyword matcher]
    G --> H[XP, unlock, vocabulary, persisted progress]
```

### AI model routing

The model choices are centralized in `EnglishLife/Models/APIConfiguration.swift` so each capability is explicit and observable in application logs.

| Capability | Model / API | What it does |
| --- | --- | --- |
| Study-path, mission guide, vocabulary, and optional text chat | `gpt-5.6-luna` via Chat Completions | Generates structured JSON for the learner's path, personalized welcome, mission phrases, dictionary data, and character responses. |
| Character portrait and location scene | `gpt-image-2` via Images API | Creates a full-body character and a people-free location background. iOS Vision then extracts the character foreground for use in the scene. |
| Live conversation | `gpt-realtime-2.1-mini` via Realtime WebSocket | Streams microphone input and character speech for turn-based voice practice. |
| Speech-to-text within the Realtime session | `gpt-4o-transcribe` | Produces learner transcripts that power the user bubble and mission-keyword matching. |

Text responses are constrained with JSON schemas where the app needs predictable data. Realtime instructions are scoped to the exact situation and required phrases so a character stays in role instead of drifting into a generic conversation.

### Caching and persistence

- `LearnerProgressStore` persists the learner level, generated path, completed situations, resume point, characters, and vocabulary with `UserDefaults`.
- `GeneratedMediaCache` stores generated portraits and backgrounds in Application Support.
- Portrait cache keys include the selected name, gender, vibe, hair, and accessory, preventing an older character template from replacing a learner's customized character.
- Existing mission guidance is reused, so reopening a started situation does not generate a new welcome or keyword list.
- Mission matching normalizes punctuation, case, diacritics, and multi-word phrases before marking a target complete.

## Built with Codex and GPT-5.6

This project was built as a collaboration between the product team and **Codex powered by GPT-5.6**. The team remained responsible for the product thesis, learner journey, game mechanics, visual direction, model choices, and acceptance decisions. Codex accelerated the execution loop.

### Where Codex accelerated the workflow

- Turned evolving wireframes and Figma/screenshot feedback into reusable SwiftUI screens, tokens, cards, tabs, map nodes, overlays, and speaking-scene components.
- Restructured an initially screen-heavy project into MVVM, split large files by feature, and moved bundled content into JSON-backed repositories.
- Implemented and iterated on the full AI pipeline: JSON study-path generation, mission guidance caching, character/location image generation, local image caching, vocabulary generation, and Realtime voice state management.
- Helped diagnose real integration issues quickly: invalid array access, Swift type errors, navigation stack/presentation conflicts, stale character cache keys, background layering, truncated labels, and Realtime echo/turn-gating issues.
- Ran repeated Swift formatting and whole-project typechecks after changes, making fast visual iteration safer.

### Where the team made the key calls

- Defined the **new-town narrative** and the five learning stages.
- Chose a **voice-only situation flow** rather than a conventional chat-first tutoring UI.
- Chose to make mission completion depend on phrases the learner actually says.
- Set the visual language: rounded storybook UI, map progression, generated full-body characters, and game-style speech bubbles.
- Decided that generated assets and mission guidance must be cached and persisted so returning learners resume an authored-feeling world.

### GPT-5.6's contribution

GPT-5.6, through Codex, was used as an engineering collaborator: it helped reason across SwiftUI state, MVVM boundaries, async API flows, and UI behavior from iterative visual feedback. At runtime, the project also routes structured text generation to the configured `gpt-5.6-luna` model. The result is a faster build-and-verify cycle while keeping product intent and final judgment with the team.

## Run locally

### Requirements

- Xcode with an iOS 17+ simulator or device.
- An OpenAI API key for the flows you want to test.
- Microphone permission for the live speaking scene.

### Setup

1. Open `EnglishLife.xcodeproj` in Xcode.
2. Copy `EnglishLife/Secret.plist.example` to `EnglishLife/Secret.plist`.
3. Add keys as needed:

   ```xml
   NARRATIVE_API_KEY
   STUDY_PATH_API_KEY
   CHARACTER_CHAT_API_KEY
   REALTIME_API_KEY
   IMAGE_GENERATION_API_KEY
   ```

   `STUDY_PATH_API_KEY` can be omitted to reuse `NARRATIVE_API_KEY`. Vocabulary generation also uses the narrative key by default.

4. Confirm `Secret.plist` is included in the app target, select an iOS 17+ destination, and run.

`Secret.plist` is gitignored. The current direct-key approach is for development; a production release should obtain short-lived Realtime credentials from a server rather than ship a long-lived key in the app bundle.

## Project map

```text
EnglishLife/
├── App/                 # App entry and route selection
├── Data/App/            # Bundled chapter, situation, character, location JSON
├── DesignSystem/         # ThemeApp colors, typography, radius, shared tokens
├── Models/               # API clients, domain models, cache, persistence
├── ViewModels/           # MVVM state and business logic
└── Views/                # Onboarding, map, mission, character, speaking, profile UI
```

## Verification

After implementation changes, the project is formatted and checked with:

```bash
xcrun swift-format format --in-place $(find EnglishLife -name '*.swift' -print)
xcrun swiftc \
  -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk \
  -target arm64-apple-ios17.0-simulator \
  -typecheck $(find EnglishLife -name '*.swift' -print)
```
