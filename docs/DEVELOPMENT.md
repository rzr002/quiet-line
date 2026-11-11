# 开发与数据说明

## 环境与构建

- macOS 14 或更新版本。
- Swift 6 工具链；原生 SwiftUI、AppKit 和 Foundation。
- 应用运行时没有第三方依赖。

```bash
bash scripts/build.sh
open "dist/Quiet Line.app"
```

默认生成当前机器架构的 `dist/Quiet Line.app` 与 `dist/Quiet-Line-macOS.zip`。`VERSION` 管理版本号，`Resources/AppIcon.icns` 随包复制。构建脚本进行本地临时签名，没有 Apple Developer ID 签名或公证。`dist` 和 Swift 构建缓存不进入 Git。

普通使用者可从 [Releases](https://github.com/rzr002/quiet-line/releases/latest) 下载预编译 DMG，无须开发环境。`启动.command` 只会在本地 `.app` 不存在时构建，更新源码后请重新运行 `bash scripts/build.sh`。

### 制作发布包

```bash
bash scripts/package-release.sh
```

脚本分别编译 `arm64-apple-macosx14.0` 和 `x86_64-apple-macosx14.0`，通过 `lipo` 合并，生成 Universal 应用、包含 Applications 入口的 DMG、ZIP、安装说明和 SHA-256 文件。输出位于 `dist/releases/<VERSION>/`，与当前运行的开发版分开。

发布前检查应用签名、两种架构、最低系统版本、只读挂载内容和从安装包取出的应用。Intel 为交叉编译，尚未实机验证。

## 测试

```bash
CLANG_MODULE_CACHE_PATH="$PWD/.build/module-cache" \
SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/module-cache" \
swift test --disable-sandbox
```

单元测试不请求网络。覆盖范围包括：交易对输入、现货/永续路由、行情错误、成交时间、滚动时间桶、曲线归一化、数据过期、文字循环布局、长文本定位及 TXT 编码。

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
- 线条模式只显示曲线、末端点和轻微光晕；文字模式只显示沿价格形状排布的正向字符。设置页显示来源与成交时间。
- 纵轴为当前可见价格的最小值到最大值，不能通过曲线高度比较绝对收益。
- 永续合约、股票现货与指数是不同的价格序列。

## 本地状态

标的、外观、位置及自定义文字保存在 `dev.quietline.demo` 偏好域。导入 TXT 后保存的是文本内容，不会在后台继续读取源文件，也不会上传文本。应用不读取交易账户。只有当前选择的公开标的会发往对应行情源。

## 文字曲线

`TextCurveFlow` 以字形宽度前缀和定位当前阅读位置，再对归一化价格曲线进行线性插值。每帧仅布局可见字形，不遍历整本小说；字形宽度在文字或字号变化时缓存。中文和组合 emoji 按 Swift Character 拆分，换行与连续空白合并为空格。

滚动速度为 0–100 px/s，字号为 9–24 pt。隐藏浮窗停止动画和定时行情请求；文字滚动本身不表示市场产生了新成交。设置预览与悬浮窗共用 `CurveView`，预览不响应拖动或双击隐藏。TXT 导入限制 5 MB，支持 UTF-8、带 BOM 的 UTF-16 和 GB18030。

文字以沿曲线的实际路程推进，每帧根据屏幕上的折线弧长定位字形，避免恒定横向速度导致文字在陡处突然加速上下移动。文字保持正向，按字形尺寸留出间距；价格曲线的高低与峰谷保留完整。核心布局保留横向定位用于兼容，浮窗与预览均启用 `alongCurve`。


## 目录

| 路径 | 内容 |
| --- | --- |
| `Sources/QuietLineCore` | 行情请求、解析、时间桶更新、曲线与活动状态 |
| `Sources/QuietLine` | 设置界面、菜单栏、透明窗口 |
| `Tests/QuietLineCoreTests` | 离线单元测试 |
| `scripts/build.sh` | 本机应用和 ZIP 打包 |
| `scripts/make-showcase.py` | 生成 README 示意素材与应用图标，需 Pillow |
| `scripts/package-release.sh` | Universal 应用、DMG、ZIP 和校验文件 |
| `.agents/product-marketing.md` | 产品定位、文案边界与证据 |
| `docs/MARKETING.md` | 仓库描述与可复制介绍草稿 |

## 参考

- [Binance TradFi 永续合约](https://www.binance.com/en/academy/articles/tradfi-assets-you-can-trade-on-binance-futures)
- [Binance 合约行情接口](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Compressed-Aggregate-Trades-List)
- [Apple 透明窗口](https://developer.apple.com/documentation/appkit/nswindow/isopaque)
