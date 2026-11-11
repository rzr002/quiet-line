# Product Marketing Context

**Document version:** v1
**Last updated:** 2026-11-11
**Status:** Drafted from the implementation and the owner's requirements. Marketing performance has not been measured.

## Product overview

**One-liner:** A transparent macOS window that shows one market curve and a small live endpoint.
**Chinese headline:** 屏幕上，只留一条线。
**Product:** Quiet Line, an early native macOS demo built with SwiftUI and AppKit.
**Category:** Minimal desktop market widget.
**Business model:** Personal project; no pricing or paid offer has been established.

Choose one symbol in a separate settings window, place the transparent curve on the desktop, and double-click it to hide. Restore it from settings. Names and prices stay in settings; the floating view draws a curve and an endpoint.

## Audience and job

The initial audience is Mac users who already know which market they follow and want to glance at its shape while keeping another application in front. They need a working source demo rather than a full trading workspace.

- Keep one chosen curve visible in a small part of the desktop.
- Hide it with a double-click and restore it deliberately from settings.
- Recognize price movement without reading a symbol or price on the floating view.

The application currently has a Chinese settings interface. A Windows version, English interface, standalone notarized installer, and multi-curve mode are not implemented.

## Problems and alternatives

Large chart windows take desktop space. A menu-bar ticker emphasizes numbers, and an editor extension ties viewing to an editor. These are different viewing formats, not proof that competitors lack any particular feature.

The distinctive behavior to show is the actual transparent curve: one selected series, a small endpoint, no floating labels, adjustable appearance, and double-click hiding. Do not claim uniqueness or superior productivity without evidence.

## Differentiation and mechanism

| Benefit | Implemented mechanism | Owning source |
| --- | --- | --- |
| A small shape stays in view | Transparent borderless floating NSPanel | Sources/QuietLine/Overlay.swift |
| The symbol stays in settings | Custom drawing renders only the path, endpoint and halo | Sources/QuietLine/Overlay.swift |
| Hiding takes one gesture | Double-click callback sets visible=false | Sources/QuietLine/main.swift |
| Real prices move the endpoint | Historical candles plus latest aggregate trade, targeted every two seconds | Sources/QuietLineCore/FeedClient.swift; Sources/QuietLine/AppModel.swift |
| A quiet desktop appearance | Adjustable color, opacity, thickness and dimensions | Sources/QuietLine/SettingsView.swift |

## Customer language

Owner's design requirements, not external testimonials:

- “透明窗口挂在某一个地方只显示一条纯粹的曲线”
- “双击就是隐藏，要再次开启就去那页面里点出”

Use: 一条线、透明、曲线、双击隐藏、设置页恢复、macOS demo。
Avoid: invisible, undetectable, guaranteed real time, full stock-market coverage, guaranteed privacy, trading terminal, proven productivity gains.

## Voice

Plain, restrained, concrete. Lead with what appears on screen. Keep the existing Chinese phrase “只留一条线”. Explain setup requirements before the first action. Support text should name the failing data source and the next useful check.

## Objections and boundaries

| Reader question | Supported answer |
| --- | --- |
| How do I open it? | Build locally on macOS with Swift 6, then open the generated .app. Launch instructions come before engineering detail. |
| Is it for Windows? | This demo is macOS-only. |
| Does it track QQQ? | It reads Binance QQQUSDT perpetual prices, which can differ from QQQ ETF shares and the Nasdaq index. |
| Is every update a price move? | The target request interval is two seconds. Network delay and time between trades still apply. |
| Can I compare curve heights? | The y-range is normalized to each visible window; height is not an absolute return comparison. |
| Can I trade from it? | Only public market-data requests are implemented. |

## Proof and claim ledger

- Features are traceable to the source paths above.
- Automated tests cover parsing, symbol routing, stale-data activity, and rolling price-series updates. A passing test count is build evidence, not a usage or market-performance claim.
- Live requests for QQQUSDT, SPYUSDT and NVDAUSDT succeeded during development on 2026-11-11. Availability is not guaranteed for another network or date.
- There are no verified adoption, conversion, latency, CPU, memory or productivity metrics.
- Showcase artwork is an illustration of the interaction, not a desktop capture or a live quote.

## Goals

**Primary action:** Build and open the macOS demo.
**Secondary action:** File a reproducible issue with system version and data-source context.
**Current distribution:** Private GitHub repository unless the owner changes visibility.

## Learnings

No campaign experiments have been run. Keep prospective headline ideas in docs/MARKETING.md; do not describe them as validated winners.

## Changelog

- v1 (2026-11-11) — Initial context from implemented desktop behavior and owner requirements; scoped launch claims and source-only setup.
