# Node HUD

[![Build](https://github.com/BadryansahBangsawan/node-hud/actions/workflows/ci.yml/badge.svg)](https://github.com/BadryansahBangsawan/node-hud/actions/workflows/ci.yml)

See which Node tools this Mac actually runs, and whether a project’s `package.json` `engines` / `packageManager` majors match.

Menu extra for macOS 14+. It lives on the **right** of the menu bar and does not show a Dock icon.

![Node HUD panel](docs/panel.png)

| | |
|---|---|
| Product | `NodeHUD` |
| Bundle ID | `engineer.badry.nodehud` |
| Status item | SF Symbol `shippingbox` (title: `node <major>`, or `Node HUD`) |
| Panel | opaque ~360×420 pt |

## Features

- Locates `node`, `npm`, `pnpm`, `bun`, `yarn`, `fnm`, `volta`.
- Search order per tool: Homebrew, `/usr/local`, Volta, asdf, `~/.local`, fnm default, process `PATH`, then login `zsh` `PATH`.
- Runs `<tool> --version` with a 3 second timeout. Missing: **not found**.
- Add project folders. Reads that folder’s `package.json` only (no walk).
- Warns when `engines.node` (and npm/pnpm/bun/yarn) or `packageManager` majors differ. Patch and minor mismatches are ignored on purpose.
- **Refresh** on appear and from the button. No timer.

## Requirements

- macOS 14 Sonoma or later
- Swift 5.9 or later (Xcode or Command Line Tools) only if you build from source
- Node tools optional — missing tools show **not found**

## Install

```bash
git clone https://github.com/BadryansahBangsawan/node-hud.git
cd node-hud
bash package-app.sh
ditto dist/NodeHUD.app /Applications/NodeHUD.app
xattr -cr /Applications/NodeHUD.app
open /Applications/NodeHUD.app
```

Ad-hoc signed (`codesign -s -`). If Gatekeeper blocks it or says it is damaged, run the `xattr` line. If it is still blocked: System Settings → Privacy & Security → Open Anyway.

Do not run `dist/NodeHUD.app` while `/Applications/NodeHUD.app` is running (same bundle ID).

Enable **Open at Login** from Settings if you want it after reboot.

## How to open

This is an `LSUIElement` extra. Proof it is running is the **shippingbox** status item on the **right** of the menu bar, not a window from Finder or Launchpad.

1. Click that extra. The panel is opaque (~360×420), not a 10px strip.
2. If the bar is full, look behind the Control Center overflow chevron **«**.
3. Double-clicking the app in Finder/Launchpad only changes the left-side app name. That is expected. There is no Dock icon.

## Usage

1. Click the extra. Tools refresh on appear.
2. **Refresh** to scan again.
3. **Add Project** chooses folders (*Choose a project folder with package.json*).
4. A folder with no root `package.json` shows **No package.json**.
5. Remove a project from its row.
6. **Settings** at the bottom of the panel: Open at Login, Quit.

### Example

If `/opt/homebrew/bin/node` is `v25.9.0`, the menu title is `node 25`.

Adding `/Users/you/Downloads/project-fun` (no root `package.json`) shows **No package.json**.

## Permissions

Folder access via the standard open panel. No Accessibility, Screen Recording, or network.

## Data

| What | Where |
|---|---|
| Projects | `~/Library/Application Support/Node HUD/projects.json` |
| Open at Login | `SMAppService.mainApp` |

A missing projects file is an empty list (Developer/Documents are not seeded). A file that will not decode is an empty list plus a red banner. The app does not crash.

## Privacy

No network. Tool paths and project folders stay on this Mac. Once per refresh the app runs `/bin/zsh -lic 'printenv PATH'` locally (3 second timeout). If zsh fails, that PATH is ignored — no banner.

## Uninstall

Delete `/Applications/NodeHUD.app`. Turn off Open at Login in Settings first if you enabled it.

```bash
rm -rf "$HOME/Library/Application Support/Node HUD"
```

## Troubleshooting

| What you see | What to do |
|---|---|
| Finder “opens” nothing / no Dock icon | Click the **shippingbox** extra on the right of the menu bar. |
| Extra missing | Overflow **«**, or `pgrep -x NodeHUD` then `open /Applications/NodeHUD.app`. |
| “Damaged” / cannot verify | `xattr -cr /Applications/NodeHUD.app`. `spctl --assess` is `rejected` even when it runs. |
| **not found** | That binary is not in the candidate paths. |
| **No package.json** | The folder has no `package.json` at its root. |
| **engines.node … vs node …** | Majors differ. Install the engine the project asks for, or change `package.json`. |
| ~10px empty strip under the bar | Reinstall from this repo (panel min height 420). |

## Development

```bash
swift build
swift build -c release --product NodeHUD
bash package-app.sh
```

Layout: `Sources/` (SwiftPM executable), `Info.plist`, `Assets/AppIcon.icns`, `package-app.sh`. Never commit `dist/`. `FunTheme.swift` is copied verbatim (no shared package).

## License

[MIT](LICENSE)
