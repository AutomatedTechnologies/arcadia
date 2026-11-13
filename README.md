# Arcadia — High Sierra Emulation + Public-Domain Media Library

Arcadia is the Detroit Automation Academy's library app for macOS High
Sierra: a native Objective-C/AppKit browser over the served
`arcadia-catalog/1` dataset — emulators with pinned High Sierra builds,
and games, film, TV, and audio whose rights basis is traced per title.

Bundle: `com.detroitautomationacademy.arcadia` · Version 1.0.0
(arcadia-test-1) · Floor: macOS 10.13 exactly. Publisher: Detroit
Automation Academy. Clean-room Academy code — no third-party code or
assets beyond the OS SDK.

## What it does (v1)

- Browse the catalog by shelf (Emulators / Games / Film / TV / Sound;
  TV appears when TV records exist) with genre groups inside each shelf.
- Per-title detail: title, system, year, version pin, High Sierra
  compatibility state — and the rights class + traced rights basis in
  plain language, shown in full. The rights basis is a feature, not
  fine print.
- Emulator entries detect a locally installed copy (standard locations
  `/Applications` and `~/Applications`, plus a user-chosen app path via
  Choose App…) and offer Open. Double-clicking an installed emulator
  row opens it too.
- Media entries show their archive source reference. A title earns an
  Open control only when its record says `distribution=hosted`; the
  current catalog hosts nothing, so media is reference-only and the app
  never shows a Play button that does nothing.
- Refresh: File ▸ Refresh Catalog (⌘R), the Refresh Catalog button, or
  the launch refresh (Preferences, on by default) re-fetches
  https://www.detroitautomationacademy.com/assets/arcadia-catalog.json
  — the app's only network fetch. A fetched catalog is adopted only
  when it validates against `arcadia-catalog/1`; offline, the bundled
  snapshot stands with no error theatrics.

## The legal fence (in-app, About + first run)

Arcadia ships **no commercial ROMs and no BIOS/firmware files**, and
says so on the welcome screen and in About. Users supply their own
files for their own hardware. The catalog lists only homebrew,
public-domain, and openly-licensed works, each with its basis traced.

## SDS-10 conformance

1. Logo — one monochrome composition (arcade arch + joystick glyph,
   drawn in-house for Arcadia): white rounded tile + ink glyph,
   transparent outside the tile (SDS-3 trimmed construction), same
   master in the bundle `AppIcon`, the Dock, the SDS-8 welcome screen,
   and About — welcome and About draw the bundle's own AppIcon through
   `AcademyAppIconView`.
2. Version at startup — the welcome screen and About show the version
   read from `Info.plist` at runtime (`AcademyWelcomeController
   .bundleVersionLine`), never hardcoded.
3. Startup sound — `Resources/startup-sound.wav`, byte-identical to
   the estate master, SHA-256
   `07a113244c6b432b22954a089ce519bd239311b14a48f26ae85214ed8c25b09a`,
   played once when the welcome presents.
4. Menu bar — code-constructed in `AppDelegate`: app menu (About
   showing the version, Preferences…, Quit ⌘Q), File (Refresh Catalog
   ⌘R, Close Window ⌘W), Edit (first-responder chain), View (shelves
   ⌘0–⌘5), Window, Help (Arcadia Help). Every item is wired.
   Attested in the bundle beside the audit entry:
   `com.detroitautomationacademy.conformance` (SDS-10 §10.5).

## Build

```
./build.sh check   # clang syntax-check against the MacOSX 10.13 SDK (no Mac needed)
./build.sh app     # assemble Arcadia.app (macOS only)
```

CI (`.github/workflows/build-arcadia.yml`, the estate's Snowfell /
Tachometer pattern) runs on `macos-15` for pushes to `build-test` and
manual dispatch: iconutil builds `Arcadia.icns` from the committed
iconset, `make app` compiles the bundle, the zip is stamped
`arcadia-test-1`, hashed, uploaded as an artifact, and published as
the `arcadia-test-1` prerelease.

Bundled data: `Arcadia/Resources/arcadia-catalog.json` is a snapshot
of the served catalog, byte-identical at build time (SHA-256
`5b557f4c168fe5e8cf3778d8873bf4fa484ed83f9a8d6e5c784dfce17f61e9ba`,
95,069 B, 74 records: 29 emulators, 18 films, 12 games, 10 audio,
5 TV — the Population Wave 1 render). All 45 media records are
`reference-only` and the 29 emulators `none` — nothing is hosted.
The catalog is consumed read-only; this repo never edits the dataset.

## Verification state

Bytes and CI prove the build; they do not prove the run. Install +
launch + browse on the owner's High Sierra Air (S4 rig verification)
stays OPEN until the owner's sitting verdict.
