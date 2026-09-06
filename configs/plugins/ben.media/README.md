# Omarchy Media Plugin (with Next Track Button)

An enhanced MPRIS media player bar widget and service for [Omarchy](https://github.com/basecamp/omarchy).

## Credits & Attribution
- **Original Author**: [Omarchy](https://github.com/basecamp/omarchy) by Basecamp / 37signals.
- **Original Plugin**: Built-in `omarchy.media` shell plugin.
- **Modifications**: Added a dedicated wide next track button (`󰒭`), enlarged play/pause hit target, and rounded hover pill indicators.

## Features
- **Now Playing Display**: Shows current track title and artist in the Omarchy status bar with auto-scrolling for long titles.
- **Interactive Controls**:
  - **Play / Pause**: Wide clickable button with hover pill and tooltip.
  - **Next Track**: Dedicated wide button (`󰒭`) to skip to the next track.
  - **Track Details / Source Switcher**: Right-click or click track text to open the popup card to control multiple MPRIS players, view album art, and manage playback.
- **Mouse Shortcuts**:
  - Left click play button: Toggle play/pause
  - Left click next button: Skip to next track
  - Middle click: Skip to next track
  - Scroll wheel: Previous / Next track
  - Right click: Open full media panel

## Installation

```bash
omarchy plugin add https://github.com/bchurch95/omarchy-media --enable
```

## License
MIT License - Inherited from Omarchy (Basecamp / 37signals). See [LICENSE](LICENSE) for details.
