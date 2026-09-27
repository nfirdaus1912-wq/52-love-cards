On a Mac: `brew install xcodegen` then in this folder `xcodegen generate` and open `FiftyTwoLoveCards.xcodeproj`.

Or create a new iOS App in Xcode (bundle `app.lovecards.fiftytwo`) and add the Swift files in `FiftyTwoLoveCards/`. Use `Config.xcconfig` for Debug/Release.

Run from repo root: `powershell -File scripts/sync-parameters.ps1` so `PACKS_URL` and IAP ids flow into Info.plist via `$(PACKS_URL)`.
