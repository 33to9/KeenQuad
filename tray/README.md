# KeenQuad developer notes

How the code is laid out, how to build, test and release it, and the implementation details that are easy to break. For what KeenQuad does and how to install it, see the [main README](../README.md).

## Layout

| Path | Contents |
|---|---|
| `Sources/CGSPrivate.h` | Declarations of the private CoreGraphics functions and the 212-byte `CGSDisplayMode` struct (bridging header) |
| `Sources/PrivateDisplay.swift` | The only place that calls private functions: reading the mode table, the current mode, and switching inside a display configuration transaction |
| `Sources/ModeModel.swift` | Pure data: modes, candidate rules, the "sharp version" rule, the menu text model |
| `Sources/AppDelegate.swift` | Menu, switching, confirmation, revert, login item, language, update check |
| `Sources/ConfirmPanel.swift` | The 15-second "Keep this resolution?" panel |
| `Sources/ConfirmedStore.swift` | Resolutions the user kept, per display |
| `Sources/Strings.swift` | Languages and all UI text, one table per language |
| `Sources/UpdateChecker.swift` | Version comparison and the GitHub Releases request |
| `Tests/main.swift`, `Tests/run-selftest.sh` | Read-only rule tests |
| `Tests/TestHook.swift` | Test-build-only hook that drives the real menu and panel |
| `build.sh` | Build, install and package |
| `make-dmg.sh`, `Resources/dmg/` | The drag-to-Applications disk image and its window background |

Private API calls stay in `CGSPrivate.h` and `PrivateDisplay.swift`, so a macOS update that breaks them can be checked in one place.

## Build

Only the Xcode Command Line Tools are needed.

```bash
./build.sh                       # build ~/Library/Caches/KeenQuad-build/KeenQuad.app
./build.sh --install             # also update /Applications/KeenQuad.app in place
./build.sh --package             # also create ../dist/KeenQuad_vX.Y.Z.dmg and _macOS.zip
```

- The app is built and ad-hoc signed on the internal disk, then checked with `codesign --verify --strict`. Don't build or run it from an exFAT volume: macOS writes `._` companion files there, and they break the code signature.
- `--install` updates the existing app's contents instead of deleting it, because deleting the app makes macOS drop its login item.
- `--package` builds the disk image with `make-dmg.sh`, which sets the window layout through Finder. The first run asks for permission to control Finder. Without it the build stops, so a DMG without its background and icon positions can't be released by accident; `KEENQUAD_DMG_ALLOW_PLAIN=1` builds one anyway. Eject any mounted "KeenQuad" volume first.
- Each rebuild changes the ad-hoc signature. If Launch at Login stops working after reinstalling, see "Login item" below.

## Test

```bash
./Tests/run-selftest.sh
```

It checks the candidate rules, menu text, sharp-version rule, language resolution, every language's strings and the update logic against a fixed mode table, then prints the menu for the connected displays. It switches nothing.

To exercise the real menu and panel, build the test build:

```bash
KEENQUAD_TEST=1 ./build.sh       # ~/Library/Caches/KeenQuad-build-test/KeenQuad.app
```

- It uses its own bundle ID, `com.pivotfrag.keenquad.test`, so it never touches the installed app's login item or settings. `build.sh` refuses to install or package it.
- `Tests/TestHook.swift` listens for the distributed notification `com.pivotfrag.keenquad.testhook`, whose object is a command (`menu`, `click:<title>`, `return`, `esc`, `state`, `snap`, `remove`, `update[:<version>[:<repo>]]`, …). Results go to `$TMPDIR/keenquad-test.txt`.
- `shotmenu` and `shotpanel:<WxH>:<WxH>` capture the real menu and confirmation panel (previous and new size) as PNGs in `$TMPDIR`, without switching anything. They capture only KeenQuad's own windows, so no Screen Recording permission is needed. The README screenshot `img/keenquad-ui.png` was made this way with the language set to English.
- Switching resolution rearranges the windows on screen. Tell whoever is using the Mac before testing, prefer larger desktops, and switch back afterwards.
- Delete the test build when you're done.

## Release

1. Bump `CFBundleShortVersionString` and `CFBundleVersion` in `Info.plist`.
2. `./build.sh --install --package`
3. Commit and push.
4. Write the notes from the template below, then publish all three files:
   ```bash
   gh release create vX.Y.Z --title "KeenQuad X.Y.Z" --notes-file notes.md \
     ../dist/KeenQuad_vX.Y.Z.dmg ../dist/KeenQuad.dmg ../dist/KeenQuad_vX.Y.Z_macOS.zip
   ```
   The DMGs are for people downloading by hand: `KeenQuad.dmg` is the same image under a fixed name, which the README links to as `releases/latest/download/KeenQuad.dmg`, so every release must include it. `install.sh` uses the ZIP.

Installed copies find the release through **Check for Updates…**, which reads the latest non-draft, non-prerelease release of the repository named in `Info.plist` under `KQUpdateRepository`. `../install.sh` installs the release's `_macOS.zip` after checking the SHA-256 that GitHub publishes for it.

### Release notes

Keep the notes in English and in two parts. **Check for Updates…** shows only the first 600 characters, so "What's new" comes first and starts with anything users must do themselves (for example, turning a setting back on).

- "What's new": user-visible changes only, as short bullets. Bold a bullet's lead-in when it calls for action.
- "Install": the same text every release, apart from the version and the DMG link. The DMG link points to this version's file, not to `latest`, so it still gives this version after newer ones come out.

Template (replace `X.Y.Z` throughout):

````markdown
### What's new in X.Y.Z

- **Something users must do, if any.** Why, and how.
- A user-visible change.

## KeenQuad X.Y.Z

### Install
**Already installed?** Use **Check for Updates…** in KeenQuad's menu, or run the one-line installer below, which updates the app in place.

**One-line install (no Gatekeeper warning)** — paste into Terminal:
```
curl -fsSL https://raw.githubusercontent.com/33to9/KeenQuad/main/install.sh | bash
```

**DMG:** download [KeenQuad_vX.Y.Z.dmg](https://github.com/33to9/KeenQuad/releases/download/vX.Y.Z/KeenQuad_vX.Y.Z.dmg), open it and drag KeenQuad onto the Applications folder. The app is not notarized by Apple, so the first launch is blocked once:
- **macOS 15 and later**: double-click (a warning appears), then **System Settings → Privacy & Security** → scroll down → **Open Anyway**
- **macOS 14**: right-click the app → **Open**

Requires a Mac with Apple silicon and macOS 14 or later. No permissions needed.

Licensed under GPL-3.0-only. The KeenQuad name and icons are reserved; see TRADEMARK.md.
````

After publishing, check that each download link in the notes works and that `releases/latest/download/KeenQuad.dmg` gives the new version.

## Implementation notes

### Mode table

- A mode is identified by its signature `WIDTHxHEIGHT@DENSITYx@HZ`, for example `1600x1000@2x@60`. Mode numbers are only valid within one enumeration and are never stored.
- Flag bits, as observed: `0x02000000` is the panel's native timing, `0x00200000` marks the HiDPI modes the public API hides, `0x40000000` marks modes not usable for the desktop.
- Candidates are modes with density 2.0 that are usable for the desktop, one per size. For each size, the deepest mode with the current refresh rate wins, otherwise the highest refresh rate. Sizes that match the panel's aspect ratio go in the main list, the rest under **Other Aspect Ratios**.
- "Sharp version": the current mode is 1x, not the panel's native mode, and a candidate of the same size exists. Switching to it skips confirmation because the desktop size and the signal to the panel don't change.

### Switching and reverting

- A resolution the user hasn't kept is applied with `.forAppOnly`. **Keep** applies it again with `.permanently`. Revert applies the previous mode with `.permanently`. If KeenQuad is killed, `.forAppOnly` makes macOS revert by itself.
- After switching, the current mode is read back and compared with the target.
- Revert falls back to `CGRestorePermanentDisplayConfiguration` when the display isn't active (for example asleep) or switching back fails.
- `SIGTERM`, `SIGINT` and `SIGHUP` go through `NSApp.terminate`, which reverts a pending resolution before quitting.
- Leaving a resolution marks it as kept, because it was just on screen. The exception is a trial that ended without Keep or Revert because its display was removed; that one is remembered in memory only and never marked as kept.
- The display reconfiguration callback is used only for display removal. KeenQuad's own switches trigger it too, so other events are ignored.

### Confirmation panel

It's a non-activating panel at modal-panel level with a timer in the `.common` run-loop mode, so the countdown runs during menu tracking. Showing it calls `NSApp.activate(ignoringOtherApps:)`; when it closes, `NSApp.hide(nil)` gives focus back. Text wraps at a fixed width because translations vary in length.

### Languages

`Strings.swift` has one `StringTable` instance per language, so a missing string doesn't compile. The current language is computed on every lookup: the user's choice (`UserDefaults` key `language`), else the first supported entry of `Locale.preferredLanguages`, else English. That's why switching languages needs no restart. System Settings paths in the strings use the names from each language's macOS.

### Login item

`SMAppService.mainApp` registers the app at its current path. If the login item ever points somewhere else (`sfltool dumpbtm` shows the URL), turning it off and on from the menu may not fix it. Remove KeenQuad in **System Settings → General → Login Items**, turn **Launch at Login** on again from the menu, and allow it under **Allow in the Background**.

### Stored data

Only `UserDefaults` in the `com.pivotfrag.keenquad` domain: `confirmedModes` (display UUID → kept signatures), `language` and `migratedLegacySettings`. On first launch, `main.swift` copies the first two from `com.keenquad.app`, the bundle ID that 0.4.0 used. No other files are written.

## Known limitations

- Private functions may change in a future macOS. If the menu is empty or switching fails, run the self-test first to see whether the mode table is still readable.
- KeenQuad only switches to modes macOS already has. It doesn't create resolutions or choose refresh rates.
- The confirmation panel appears only on the display being switched. If that display goes black, press Esc or wait 15 seconds.
- **Switch to Sharp** skips confirmation. When the HiDPI version has no mode at the current refresh rate, the refresh rate changes without the 15-second safety net.
- Displays that are asleep aren't in `CGGetActiveDisplayList`, so they don't appear in the menu.
- Some remote-desktop connections and display utilities make macOS re-detect displays on wake, which can reset the resolution to the default. Pick the resolution again from the menu.
