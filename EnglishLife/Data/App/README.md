# App content data

- `chapters.json`: roadmap chapter metadata.
- `situations.json`: roadmap situations. Add one JSON object per new node; `id` must remain globally unique and `chapterId` must match `chapters.json`.
- `characters.json`: reusable character templates and asset names.

Place character images in `Resources/Assets.xcassets/Characters.imageset` and map artwork in `Resources/Assets.xcassets/Map.imageset`. Drag images into the corresponding image set in Xcode; it will update `Contents.json` automatically.
