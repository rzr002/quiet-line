# 开发与数据说明

## 环境与构建

- macOS 14 或更新版本。
- Swift 6 工具链；原生 SwiftUI、AppKit 和 Foundation。
- 应用运行时没有第三方依赖。

```bash
bash scripts/build.sh
open "dist/Quiet Line.app"
```

生成当前机器架构的 `dist/Quiet Line.app` 与 `dist/Quiet-Line-macOS.zip`。构建脚本进行本地临时签名，没有 Apple 开发者签名或公证。`dist` 和 Swift 构建缓存不进入 Git。

源码编译后才能获得 `.app`；仓库中没有可直接运行的预编译安装包。`启动.command` 只会在 `.app` 不存在时构建，更新源码后请重新运行 `bash scripts/build.sh`。

## 测试

```bash
CLANG_MODULE_CACHE_PATH="$PWD/.build/module-cache" \
SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/module-cache" \
swift test --disable-sandbox
```

单元测试不请求网络。覆盖范围包括：交易对输入、现货/永续路由、行情错误、成交时间、滚动时间桶、曲线归一化和数据过期。

有网络时可手动验证内置 QQQUSDT、SPYUSDT、NVDAUSDT 的历史曲线和最新成交：

```bash
"dist/Quiet Line.app/Contents/MacOS/QuietLine" --check-feeds
```

这项检查只能证明检查时刻和当前网络下接口可用。

## 网络配置

| 市场 | 公开行情入口 |
| --- | --- |
| 现货 | `https://data-api.binance.vision/api/v3/` |
| 永续 | `https://www.binance.com/fapi/v1/` |

永续客户端首先尝试本机 HTTP 代理 `127.0.0.1:7897`，连接异常时尝试直连。代码没有修改系统代理、代理节点或网络安全设置。这个默认端口来自最初 demo 的本机环境，其他设备可能需要调整。

设置其他端口并直接运行可执行文件：

```bash
QUIETLINE_PROXY_PORT=7890 "dist/Quiet Line.app/Contents/MacOS/QuietLine"
```

从 Finder 双击 `.app` 通常不会继承终端变量。若已有应用实例，先从菜单栏退出，再通过以上命令启动。

公开网页接口可能变化、限流或返回地区不可用错误。当前实现不会承诺跨网络可用，也不会把不可用的永续合约替换为另一种资产。

## 价格与时间口径

- `1 小时 / 4 小时` 使用 `1m` K 线，分别保留 60 / 240 个点。
- `24 小时` 使用 `5m` K 线，保留 288 个点。
- 最新聚合成交按交易所时间戳更新最后一个时间桶，旧成交不会将序列倒退。
- 目标请求周期为 2 秒；请求串行进行，网络耗时会延长实际间隔。
- 浮窗只显示曲线、末端点和轻微光晕。设置页显示来源与成交时间。
- 纵轴为当前可见价格的最小值到最大值，不能通过曲线高度比较绝对收益。
- 永续合约、股票现货与指数是不同的价格序列。

## 本地状态

标的、外观、位置保存在 `dev.quietline.demo` 偏好域。应用不读取交易账户。只有当前选择的公开标的会发往对应行情源。

## 目录

| 路径 | 内容 |
| --- | --- |
| `Sources/QuietLineCore` | 行情请求、解析、时间桶更新、曲线与活动状态 |
| `Sources/QuietLine` | 设置界面、菜单栏、透明窗口 |
| `Tests/QuietLineCoreTests` | 离线单元测试 |
| `scripts/build.sh` | 本机应用和 ZIP 打包 |
| `scripts/make-showcase.py` | 生成 README 的示意素材，需 Pillow |
| `.agents/product-marketing.md` | 产品定位、文案边界与证据 |
| `docs/MARKETING.md` | 仓库描述与可复制介绍草稿 |

## 参考

- [Binance TradFi 永续合约](https://www.binance.com/en/academy/articles/tradfi-assets-you-can-trade-on-binance-futures)
- [Binance 合约行情接口](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Compressed-Aggregate-Trades-List)
- [Apple 透明窗口](https://developer.apple.com/documentation/appkit/nswindow/isopaque)
