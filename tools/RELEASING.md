# Releasing Megarift Survivors

Package id: `io.github.dwr3ker.megarift` · repository: https://github.com/Dwr3ker/Megarift-Survivors · version in `project.godot` (`config/version`) and `version/code` in `export_presets.cfg`.

## Build a signed release APK

```
powershell -ExecutionPolicy Bypass -File tools\build_release.ps1
```

Output: `build\megarift-survivors-<version>.apk` (path set in `export_presets.cfg`; override with `-Out`).

The script reads `%USERPROFILE%\Android\release\keystore-credentials.txt` (lines `keystore=`, `alias=`, `password=`) and gives them to Godot through
`GODOT_ANDROID_KEYSTORE_RELEASE_PATH / _USER / _PASSWORD` for that one process. Nothing secret is written into the project.
Needs Godot 4.4.x (the executable on the PATH, in `$env:GODOT`, or passed with `-Godot`) + export templates, JDK 17 and the Android SDK (build-tools 35.0.1, platform 35), as in the README.

## Before every release
1. Bump `config/version` (project.godot) and **increase** `version/code` (export_presets.cfg) — Android refuses to install a lower code over a higher one.
2. Add a new top entry to `scripts/patchnotes.gd` (Spanish text) and its English lines to `data/lang_en.json`; write `RELEASE_NOTES_v<version>.md`.
3. Run the tests (`tools/tests/*_test.gd`, see README; run them from the project folder) and check `RESULT: PASS` for each.
4. Build, then verify the result:
   ```
   apksigner verify --print-certs build\megarift-survivors-<version>.apk
   apkanalyzer manifest application-id build\megarift-survivors-<version>.apk
   ```
   The certificate SHA-256 must equal the release key's (see below); the id must be `io.github.dwr3ker.megarift`.

## The signing key — read this
- Files: `%USERPROFILE%\Android\release\pokesurvivors-release.keystore` and `keystore-credentials.txt` (owner-only permissions).
- Certificate SHA-256: `BE:72:4C:B1:D0:A5:E3:4E:B5:09:FC:3D:DE:88:6B:79:57:C9:54:12:28:86:15:88:46:B5:DD:76:A4:F6:8C:30` (RSA 4096, valid until 2126).
- **Back up both files together** (for example in a password manager that stores attachments, plus an offline copy). **If the keystore or its password is lost, installed copies can never be updated**; people would have to uninstall and lose their saves. If it leaks, anyone can sign an update that Android accepts as yours.
- Never commit them: `.gitignore` already excludes `*.keystore`, `*.jks`, `keystore-credentials*`, `*.apk`, `*.idsig`, `*.aab`.

## Not covered yet
- **Play Store:** not planned (the project is distributed through GitHub releases).

## Publishing a release on GitHub
- **Pre-release (test builds, current stage):** create a release with a tag like `v0.1.0-alpha.1`, tick **"Set as a pre-release"**, attach the signed `.apk` and paste `RELEASE_NOTES_v<version>.md`. Testers download and install it by hand. GitHub's "latest release" API, which the in-game update check uses, **ignores pre-releases and drafts**, so test builds are never offered as updates in the app.
- **Stable release (later):** the same, without the pre-release box. The tag number must be higher than the installed `config/version` (for example `v0.2.0` over `0.1.0`); players on older versions then see the update notice with a download button. The tag's numbers decide; suffixes such as `-alpha.1` are ignored in the comparison.
- The repository must be **public** for downloads and the update check to work without signing in. While it is private, only you can download its releases.
