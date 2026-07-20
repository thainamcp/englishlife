# App content data

- `chapters.json`: roadmap chapter metadata.
- `situations.json`: roadmap situations. Each node includes `characterId` and `locationId`; IDs must match `characters.json` and `locations.json`.
- `characters.json`: reusable character templates used by the generated portrait cache.
- `locations.json`: reusable location prompts used by the generated background cache.

Place character images in `Resources/Assets.xcassets/Characters.imageset` and map artwork in `Resources/Assets.xcassets/Map.imageset`. Drag images into the corresponding image set in Xcode; it will update `Contents.json` automatically.
