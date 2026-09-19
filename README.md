# Node HUD

Show local Node toolchain versions and `package.json` `engines` / `packageManager` mismatches.

Menu extra for macOS 14+. It lives on the **right** of the menu bar and does not show a Dock icon.

| | |
|---|---|
| Product | `NodeHUD` |
| Bundle ID | `engineer.badry.nodehud` |
| Status item | SF Symbol `shippingbox` |
| Panel | opaque ~360×420 pt |

## Features

- Locates `node`, `npm`, `pnpm`, `bun`, `yarn`, `fnm`, `volta` (Homebrew, Volta, asdf, fnm, PATH, login `zsh` PATH).
- `--version` with a 3s timeout. Missing tool: **not found**.
- Add project folders; reads that folder’s `package.json` only (no walk).
- Warns when `engines.*` or `packageManager` major differs from the located tool.
- **Refresh** (no timer). Menu title is `node <major>` or `Node HUD`.

## Requirements

- macOS 14 Sonoma or later
- Swift 5.9 or later only if you build from source
- Node tools optional — missing tools show **not found**

## Install

Build from source:

```bash
git clone https://github.com/BadryansahBangsawan/node-hud.git
cd node-hud
bash package-app.sh
ditto dist/NodeHUD.app /Applications/NodeHUD.app
xattr -cr /Applications/NodeHUD.app
open /Applications/NodeHUD.app
```

Ad-hoc signed (`codesign -s -`). If Gatekeeper blocks it or says it is damaged, run the `xattr` line above. If still blocked: System Settings → Privacy & Security → Open Anyway.

Do not run `dist/` next to a copy in `/Applications` (same bundle ID).

Enable **Open at Login** from Settings if you want it after reboot.

## How to open

This is an `LSUIElement` extra. Proof it is running is the **shippingbox** status item on the **right** of the menu bar.

1. Click that extra. The panel is opaque (~360×420), not a 10px strip.
2. If the bar is full, look behind the Control Center overflow chevron **«**.
3. Double-clicking in Finder/Launchpad does not open a document window. That is expected. There is no Dock icon.

## Usage

- Open the extra: tools refresh on appear. **Refresh** to scan again.
- **Add Project** chooses folders (message: *Choose a project folder with package.json*).
- Missing `package.json`: red **No package.json**.
- **Settings** at the bottom: Open at Login, Quit.

## Permissions

Folder access via the standard open panel. No Accessibility or Screen Recording. No network.

## Data

Projects: `~/Library/Application Support/Node HUD/projects.json`. Missing file is empty (not seeded). Decode failure is empty plus a red banner.

## Privacy

No network. Tool paths and project folders stay on this Mac. `zsh -lic printenv PATH` runs locally once per refresh.

## Uninstall

Delete `/Applications/NodeHUD.app`. Turn off Open at Login in Settings first if you enabled it.

```bash
rm -rf "$HOME/Library/Application Support/Node HUD"
```

## Troubleshooting

| What you see | What to do |
|---|---|
| No Dock icon | Click the **shippingbox** extra on the right of the menu bar. |
| Extra missing | Overflow **«**, or `open /Applications/NodeHUD.app`. |
| “Damaged” | `xattr -cr /Applications/NodeHUD.app` |
| **not found** | That binary is not in the candidate paths. |
| **No package.json** | The folder you added has no `package.json` at its root. |
| Tiny capsule / only Settings | Reinstall from this repo (panel min height 420). |

## Development

```bash
swift build
swift build -c release --product NodeHUD
```

Layout: `Sources/` (SwiftPM executable), `Info.plist`, `Assets/AppIcon.icns`, `package-app.sh`. Never commit `dist/`. FunTheme.swift is copied verbatim (no shared package).

## License

[MIT](LICENSE)
