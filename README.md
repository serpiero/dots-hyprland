<div align="center">
  <h1>【 Arc Steel · Hyprland dotfiles 】</h1>
  <p>A dark desktop with a palette of your own.</p>

  <a href="https://github.com/serpiero/dots-hyprland/commits/main"><img alt="Last commit" src="https://img.shields.io/github/last-commit/serpiero/dots-hyprland?style=for-the-badge&amp;color=9aacc1&amp;logo=git&amp;logoColor=D9E0EE&amp;labelColor=1E202B"></a>
  <a href="https://github.com/serpiero/dots-hyprland/stargazers"><img alt="GitHub stars" src="https://img.shields.io/github/stars/serpiero/dots-hyprland?style=for-the-badge&amp;color=cbc4cb&amp;logo=andela&amp;logoColor=D9E0EE&amp;labelColor=1E202B"></a>
  <a href="https://github.com/serpiero/dots-hyprland"><img alt="Repository size" src="https://img.shields.io/github/repo-size/serpiero/dots-hyprland?style=for-the-badge&amp;color=9aafa4&amp;label=SIZE&amp;logo=protondrive&amp;logoColor=D9E0EE&amp;labelColor=1E202B"></a>
  <a href="https://quickshell.org/"><img alt="Built on Quickshell" src="https://img.shields.io/badge/Built_on-Quickshell-b9ae98?style=for-the-badge&amp;labelColor=1E202B"></a>
  <a href="https://hypr.land/"><img alt="Built on Hyprland" src="https://img.shields.io/badge/Built_on-Hyprland-9aacc1?style=for-the-badge&amp;logo=hyprland&amp;logoColor=D9E0EE&amp;labelColor=1E202B"></a>
</div>

<h2 align="center">• overview •</h2>

**Arc Steel** is a dark, minimal, high-contrast desktop for **Hyprland** and **Quickshell**. Built on the architecture of [Illogical Impulse](https://github.com/end-4/dots-hyprland), it brings together soft glass surfaces, compact controls, and a consistent visual language across your desktop and applications.

> [!NOTE]
> **One color. A complete dark desktop.** The **Live Dark Palette Engine** carries your palette across 24+ desktop components and application integrations. Start with **Graphite** (the default), **Metal Red**, or **Steel**, or turn any `#RRGGBB` color into a custom palette—from cool neutrals to warm amber. A refined Quickshell interface keeps the controls close at hand.

<h2 align="center">• showcase & highlights •</h2>

**Unified Live Theming Engine**  
Choose a saved theme or create one from any hex color in **Settings → Quick**. Shared color roles connect Quickshell, Hyprland, Kitty, btop, Rofi, GTK 2/3/4, Qt 5/6/Quick, VS Code, and more. The same engine also prepares Spotify, Firefox, MiniMeters, qBittorrent, and RetroArch. Compatible adapters update live; applications that cache their styling may need to be reopened. Save your favorite presets, switch palettes on the fly, or generate new ones effortlessly.

**Refined Quickshell Interface · `ii` family**  
An adaptable pill-style top bar, interactive Control Center, responsive on-screen displays, and a visual wallpaper selector make everyday actions feel immediate. Open wallpapers with **Ctrl + Super + T** and native **Settings** with **Super + I** to adjust System Blur, mouse behavior, bars, and opacity in real time.

**AI & Productivity Sidebars**  
**ChatGPT** and **Gemini** are ready as the default web providers in **Intelligence**. Sign in with your own account when you choose; no accounts or API keys are bundled. Use Settings to add more providers or configure your own keys. The smart launcher also brings keyword web searches such as **`?yt`** and **`?wiki`** to the desktop.

**Lua-Powered Hyprland Configuration**  
The modular [`arc-steel/theme.lua`](arc-steel/theme.lua) layer keeps visual overrides, animations, and window rules separate from the underlying Hyprland configuration. Shared palette tokens connect compositor accents to the rest of the desktop. Your installation can keep personal overrides in `local.lua`.

<details>
  <summary><b>Explore the palette integrations</b></summary>

- **Desktop:** Hyprland, Quickshell, Rofi, lock screen, and shared context menus.
- **Toolkits:** GTK 2/3/4, KDE colors, Qt 5/6 Widgets, Qt Quick, and KTextEditor.
- **Terminals:** Kitty, Alacritty, Konsole, Starship, btop, and Cava.
- **Applications:** VS Code, Firefox, Electron clients, WebKit surfaces, Spotify, MiniMeters, qBittorrent, and RetroArch.

The engine generates interface colors. Documents, artwork, games, and application-specific skins keep their own visual content. Spotify uses the native client with generated CSS.

</details>

<h2 align="center">• keybindings •</h2>

<table align="center">
  <thead><tr><th>Keybind</th><th>Action</th></tr></thead>
  <tbody>
    <tr><td><kbd>Super</kbd> + <kbd>/</kbd></td><td>Visual keybinding cheatsheet</td></tr>
    <tr><td><kbd>Super</kbd> + <kbd>I</kbd></td><td>Arc Steel Settings</td></tr>
    <tr><td><kbd>Ctrl</kbd> + <kbd>Super</kbd> + <kbd>T</kbd></td><td>Visual wallpaper selector</td></tr>
    <tr><td><kbd>Super</kbd> + <kbd>A</kbd></td><td>Left sidebar</td></tr>
    <tr><td><kbd>Ctrl</kbd> + <kbd>Super</kbd> + <kbd>A</kbd></td><td>Intelligence</td></tr>
    <tr><td><kbd>Super</kbd> + <kbd>N</kbd></td><td>Control Center and right sidebar</td></tr>
    <tr><td><kbd>Super</kbd> + <kbd>R</kbd></td><td>Application launcher</td></tr>
    <tr><td><kbd>Super</kbd> + <kbd>Enter</kbd></td><td>Terminal</td></tr>
    <tr><td><kbd>Super</kbd> + <kbd>H</kbd></td><td>Clipboard history</td></tr>
    <tr><td><kbd>Super</kbd> + <kbd>V</kbd></td><td>Toggle floating window</td></tr>
    <tr><td><kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd></td><td>Select and annotate a screenshot</td></tr>
    <tr><td><kbd>Print</kbd></td><td>Capture the full screen</td></tr>
    <tr><td><kbd>Ctrl</kbd> + <kbd>Print</kbd></td><td>Capture the active window</td></tr>
  </tbody>
</table>

<h2 align="center">• get started •</h2>

Designed for **Arch Linux / CachyOS with Lua-capable Hyprland**. The included Quickshell build recipe pins its source revision and builds the WebEngine-enabled runtime against the destination system's Qt libraries.

```sh
git clone https://github.com/serpiero/dots-hyprland.git
cd dots-hyprland
./install.sh --verify-source
./install.sh --check
# Install dependencies if needed:
./install.sh --dependencies
./install.sh --install
```

The installer backs up the existing Hyprland entry point and installs Arc Steel in `~/.local/share/rice-profiles`.

Start in **Settings → Quick** to choose your palette. Add your own Intelligence providers and keys through Settings, and use the visual cheatsheet to discover the rest of the desktop.

<details>
  <summary><b>Source layout</b></summary>

| Location | Purpose |
| --- | --- |
| [`arc-steel/`](arc-steel/) | Hyprland visual layer and application templates |
| [`ui/`](ui/) | Quickshell interface, Settings, services, and sidebars |
| [`themes/`](themes/) | Graphite, Metal Red, and Steel presets |
| [`styles/`](styles/) | Shared application color templates and native adapters |
| [`theme-manager.py`](theme-manager.py) | Saved palettes, favorites, and custom color generation |
| [`theme.py`](theme.py) / [`palette.py`](palette.py) | Palette validation and generation |
| [`hyprland-base/`](hyprland-base/) | Modular Hyprland base configuration |
| [`tools/`](tools/) | Installation, build recipes, and validation |

</details>

<h2 align="center">• credits •</h2>

**[end-4 / dots-hyprland · Illogical Impulse](https://github.com/end-4/dots-hyprland)** provides the original Quickshell and Hyprland architecture at the heart of Arc Steel. Thank you to end-4 and the upstream contributors for building the foundation of this desktop.

Built with **[Hyprland](https://hypr.land/)**, **[Quickshell](https://quickshell.org/)**, Qt, and the work of the wider open-source community.

Licensed under **[GPL-3.0](LICENSE)**. Third-party notices and asset licenses are included in [`licenses/`](licenses/).
