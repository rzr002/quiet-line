# Quiet Line 文案与展示素材

当前内容是可用草稿；没有投放、发布到社区或经过转化测试。

## 已采用的定位

**中文标题：** 屏幕上，只留一条线。

**英文一句话：** One market curve on your desktop.

**GitHub About：** A transparent macOS market curve. Choose a symbol, place one line, double-click to hide.

**主题：** macos, swift, swiftui, appkit, desktop-widget, market-data, binance, minimalism

主动作是「在 Mac 上启动」。当前是源码 demo，因此入口明确告诉读者先准备 Swift 6，再构建应用。

## 选择理由

| 文案或素材 | 为什么保留 |
| --- | --- |
| “只留一条线” | 直接对应浮窗实际绘制内容，也保留了最初需求的声音 |
| “双击隐藏，设置页恢复” | 读者能照做，省去对全局快捷键的记忆 |
| 单独写 macOS 和源码构建要求 | 解决第一次看到项目时不知道怎么打开的问题 |
| 交互示意而非合成截图 | 清楚展示小窗与隐藏动作，同时说明不是实机截图或实时价格 |
| 标明永续价格口径 | 避免把 QQQUSDT 描述成 QQQ ETF 现货 |

## 备用标题

尚未验证，保留供后续比较：

1. **把一个标的，放成桌面一角的曲线。** 更强调选择与摆放。
2. **看一眼走势，双击收起。** 更强调使用动作。

备用主动作：「构建你的第一条桌面曲线」。当前采用更直接的「在 Mac 上启动」。

## 中文介绍草稿

Quiet Line 是一个 macOS 透明曲线 demo。选好标的，把一条曲线放在桌面一角；双击就能隐藏，再到设置页恢复。

悬浮窗口只显示走势和右端的小圆点。符号名称、行情来源、颜色和尺寸都放在单独的设置窗口里。支持 Binance 的 QQQUSDT、SPYUSDT、美股映射永续，以及 BTC、ETH、SOL 等现货交易对，以每 2 秒为目标间隔读取最新成交。

当前提供源码，需要 macOS 14+ 与 Swift 6。价格来源是对应币安市场，可能与美股现货不同。

仓库：https://github.com/rzr002/quiet-line

## English draft

Quiet Line puts one transparent market curve on your Mac desktop. Choose a symbol, drag the curve into place, and double-click to hide it. Restore it from settings.

The floating window draws a curve and a small endpoint. Symbol names and controls live in a separate settings window. It supports Binance spot pairs and perpetual contracts including QQQUSDT, SPYUSDT and NVDAUSDT.

This is an early source demo for macOS 14+ and Swift 6. The settings interface is in Chinese. Perpetual-contract prices can differ from the underlying shares or index.

Repository: https://github.com/rzr002/quiet-line

## 素材

- `assets/hero.svg`：README 品牌图，向量示意。
- `assets/interaction.gif`：拖动、双击隐藏和设置恢复的交互示意。
- 二者都不包含账户、持仓、私人桌面或实时行情。
- 这些素材不是产品性能、延迟、用户数或投资收益的证据。

## 技能来源

本轮参考并应用：

- [product-marketing](https://github.com/coreyhaines31/marketingskills/blob/main/skills/product-marketing/SKILL.md)：定位、受众、异议与证据。
- [copywriting](https://github.com/coreyhaines31/marketingskills/blob/main/skills/copywriting/SKILL.md)：保留原稿声音、明确主动作、删去没有证据的宣传说法。
