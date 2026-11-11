<p align="center">
  <img src="docs/assets/hero.svg" alt="Quiet Line: one market curve on your Mac desktop" width="1200" />
</p>

# Quiet Line

**One market curve on your desktop.**

Choose a symbol, place its transparent curve in a corner, and double-click to hide it. The floating window shows the curve and a small endpoint. Symbol names and settings live in a separate window.

[Build the Mac demo](#run-on-your-mac) · [简体中文](README.md) · [Development](docs/DEVELOPMENT.md) · [Report an issue](https://github.com/rzr002/quiet-line/issues)

**Early source demo for macOS 14+. Building requires Swift 6. The settings interface is currently in Chinese.**

## Keep one shape in view

<img src="docs/assets/interaction.gif" alt="Illustrated interaction: place a curve, double-click to hide, restore from settings" width="960" />

*Interaction illustration using an example curve. This is not a desktop capture or a live quote.*

| Action | Interaction |
| --- | --- |
| Choose a symbol | Click it in settings |
| Place the curve | Drag its transparent window |
| Hide it | Double-click the curve area |
| Bring it back | Open settings and click 显示曲线 (Show curve) |
| Adjust its appearance | Change color, opacity, stroke width and dimensions |
| Open settings or quit | Use the curve icon in the macOS menu bar |

The borderless window stays above other windows while settings can be closed separately. Its small endpoint breathes while the data is fresh and the connection is healthy. New prices move the endpoint with a short transition.

## Run on your Mac

With macOS 14+ and a Swift 6 toolchain installed:

```bash
git clone https://github.com/rzr002/quiet-line.git
cd quiet-line
bash scripts/build.sh
open "dist/Quiet Line.app"
```

Choose a symbol in the left sidebar, drag the curve into place, and click 收起设置 (Close settings). On subsequent launches, open the generated `.app` directly.

If you already have the project folder, double-click `启动.command` to build when needed and launch it.

There is no standalone installer yet. The script builds for the current Mac architecture and applies a local ad-hoc signature. The app is not Apple-notarized.

## Markets

| Type | Built-in examples | Actual price source |
| --- | --- | --- |
| US ETF exposure | QQQUSDT, SPYUSDT | Binance USDⓈ-M perpetual contracts |
| US equity exposure | NVDAUSDT, AAPLUSDT, TSLAUSDT, MSFTUSDT, GOOGLUSDT, AMZNUSDT, METAUSDT | Binance USDⓈ-M perpetual contracts |
| Crypto | BTC, ETH, SOL, BNB, XRP, DOGE, ADA and AVAX USDT pairs | Binance spot |

QQQUSDT is selected by default. Choose 永续 (perpetual) or 现货 (spot) in settings to add another symbol.

**QQQUSDT is a perpetual contract. Its price can differ from QQQ ETF shares and the Nasdaq index.** Contract availability depends on the upstream market and the current network.

## How the curve updates

Choose a 1-hour, 4-hour or 24-hour window. Quiet Line loads historical candles and then targets a two-second interval for the latest aggregate trade. It updates the last point within the current bucket and advances the window when a new bucket begins.

Hiding the curve pauses scheduled requests. A stale connection stops the breathing endpoint; a failed request hides the curve and displays an error in settings. Network delay, upstream processing and quiet trading periods affect what changes on screen.

The y-range is normalized to the visible series. Curve height is not an absolute return comparison between symbols.

## Scope

This is a macOS-only, single-curve demo. It reads public market data without account credentials and does not execute trades. Preferences stay on the local Mac.

For connectivity, tests and build details, see [Development](docs/DEVELOPMENT.md). Report issues with your macOS version, symbol, spot/perpetual selection and the error shown in settings.
