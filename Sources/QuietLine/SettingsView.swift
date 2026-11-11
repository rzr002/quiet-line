import SwiftUI
import QuietLineCore
import UniformTypeIdentifiers

private let paper = Color(red: 0.965, green: 0.957, blue: 0.937)
private let darkInk = Color(red: 0.20, green: 0.24, blue: 0.22)
private let muted = Color(red: 0.47, green: 0.49, blue: 0.45)

struct SettingsView: View {
    @ObservedObject var model: AppModel
    let onDismiss: () -> Void
    @State private var code = ""
    @State private var venue: Venue = .perpetual
    @State private var addError: String?
    @State private var importingText = false
    @State private var textError: String?

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Rectangle().fill(darkInk.opacity(0.10)).frame(width: 1)
            VStack(alignment: .leading, spacing: 22) {
                header
                preview
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        displayMode
                        if model.curveMode == .text { textControls }
                        appearance
                    }.padding(.trailing, 4)
                }
                footer
            }
            .padding(.horizontal, 28).padding(.top, 28).padding(.bottom, 22)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: 700, height: 672)
        .background(paper).foregroundStyle(darkInk).tint(darkInk).preferredColorScheme(.light)
        .fileImporter(isPresented: $importingText, allowedContentTypes: [.plainText]) { result in
            do {
                let url = try result.get()
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                guard size <= 5 * 1_024 * 1_024 else {
                    textError = "TXT 请控制在 5 MB 以内，可以按章节导入。"; return
                }
                model.textContent = try TextCurveContent.decode(Data(contentsOf: url))
                textError = nil
            } catch { textError = error.localizedDescription }
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 3) {
                Text("quiet line").font(.system(size: 25, weight: .regular, design: .serif)).tracking(-1)
                Text("只留一条线。").font(.system(size: 11)).foregroundStyle(muted)
            }.padding(.top, 30).padding(.horizontal, 20)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach([Venue.perpetual, Venue.spot], id: \.self) { group in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(group.title).font(.system(size: 10, weight: .medium))
                                .foregroundStyle(muted).padding(.horizontal, 12).padding(.bottom, 4)
                            ForEach(model.instruments.filter { ($0.venue ?? .spot) == group }) { item in
                                Button { model.select(item) } label: {
                                    HStack(spacing: 7) {
                                        Circle().fill(model.selected.id == item.id ? darkInk : .clear).frame(width: 4, height: 4)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.name).font(.system(size: 12, weight: model.selected.id == item.id ? .semibold : .regular))
                                            Text(item.symbol).font(.system(size: 9, design: .monospaced)).foregroundStyle(muted)
                                        }
                                        Spacer(minLength: 0)
                                    }
                                    .padding(.horizontal, 10).padding(.vertical, 7)
                                    .background(model.selected.id == item.id ? darkInk.opacity(0.07) : .clear, in: RoundedRectangle(cornerRadius: 5))
                                    .contentShape(Rectangle())
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                }.padding(.horizontal, 8)
            }
            Text("标的只在这里出现").font(.system(size: 10)).foregroundStyle(muted)
                .padding(.horizontal, 20).padding(.bottom, 20)
        }.frame(width: 184).background(darkInk.opacity(0.025))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("你的桌面，只留走势。")
                    .font(.system(size: 23, weight: .regular, design: .serif)).tracking(-0.7)
                Spacer()
                Text("QUIET LINE").font(.system(size: 9, design: .monospaced)).foregroundStyle(muted)
            }
            HStack {
                Text(model.curveMode == .line ? "一条曲线，一个呼吸的点。其余都藏起来。" : "让文字沿着行情起伏，慢慢读，也慢慢看。")
                    .font(.system(size: 11)).foregroundStyle(muted)
                Spacer(minLength: 8)
                Button(model.visible ? "隐藏曲线" : "显示曲线") { model.visible.toggle() }.controlSize(.mini)
            }
        }
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(model.selected.name).font(.system(size: 12, weight: .medium))
                Spacer()
                Picker("显示范围", selection: $model.range) {
                    ForEach(HistoryRange.allCases, id: \.self) { Text($0.title).tag($0) }
                }.pickerStyle(.segmented).controlSize(.mini).frame(width: 178)
                Button { model.refresh() } label: {
                    Image(systemName: "arrow.clockwise").font(.system(size: 11))
                }.buttonStyle(.plain).disabled(model.loading).help("刷新行情")
            }
            ZStack {
                CurvePreview(model: model)
                if model.series == nil {
                    Text(model.loading ? "正在获取曲线…" : "等待可用行情")
                        .font(.system(size: 11)).foregroundStyle(muted)
                }
                if model.curveMode == .text && !model.textContent.contains(where: { !$0.isWhitespace }) {
                    Text("写点文字，或导入一个 TXT")
                        .font(.system(size: 11)).foregroundStyle(muted)
                }
            }.frame(height: 88).padding(.vertical, 10)
            HStack(spacing: 5) {
                Circle().fill(model.error == nil ? Color(red: 0.39, green: 0.53, blue: 0.43) : .orange).frame(width: 4, height: 4)
                Text(status).font(.system(size: 9, design: .monospaced)).foregroundStyle(muted)
                Spacer()
                if model.loading { ProgressView().controlSize(.mini).scaleEffect(0.7) }
            }
        }
        .padding(16)
        .background(.white.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(darkInk.opacity(0.09), lineWidth: 0.6))
    }

    private var status: String {
        if model.error != nil { return "暂不可用 · 曲线已隐藏，10 秒后重试" }
        guard let series = model.series, let last = series.points.last else { return "Binance · 24 小时交易 · 每 2 秒更新" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        return "成交 \(formatter.string(from: last.time)) 北京 · 每 2 秒更新"
    }

    private var displayMode: some View {
        HStack {
            label("显示方式")
            Spacer()
            Picker("显示方式", selection: $model.curveMode) {
                Text("线条").tag(CurveMode.line)
                Text("文字曲线").tag(CurveMode.text)
            }.pickerStyle(.segmented).labelsHidden().frame(width: 205)
        }
    }

    private var textControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                label("沿线文字")
                Spacer()
                Button("导入 TXT…") { importingText = true }.controlSize(.small)
            }
            if model.textContent.utf8.count > 16_000 {
                VStack(alignment: .leading, spacing: 6) {
                    Text(String(model.textContent.prefix(130)) + "…")
                        .font(.system(size: 11)).lineLimit(3)
                    HStack {
                        Text("已载入长文本 · 自动循环").font(.system(size: 10)).foregroundStyle(muted)
                        Spacer()
                        Button("清空重写") { model.textContent = "" }.controlSize(.mini)
                    }
                }.padding(10).background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 5))
            } else {
                TextEditor(text: $model.textContent)
                    .font(.system(size: 12)).scrollContentBackground(.hidden)
                    .padding(6).frame(height: 68)
                    .background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 5))
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(darkInk.opacity(0.12), lineWidth: 0.6))
                    .accessibilityLabel("循环显示的文字")
            }
            HStack(spacing: 8) {
                Button("座右铭") { useText("行到水穷处，坐看云起时。") }
                Button("天气文案") { useText("今日天气文案示例：晴间多云，微风经过窗边，适合出门散步。") }
                Button("小说片段") { useText("末班车驶过旧桥时，江面上亮起了第一盏灯。林舟把信折好，放进大衣口袋，走向那家还没打烊的书店。门铃响起，柜台后的猫抬了抬眼。") }
                Button("青玉案") { useText("凌波不过横塘路，但目送、芳尘去。锦瑟华年谁与度？月桥花院，琐窗朱户，只有春知处。飞云冉冉蘅皋暮，彩笔新题断肠句。试问闲情都几许？一川烟草，满城风絮，梅子黄时雨。") }
            }.controlSize(.mini)
            sliderRow("滚动速度", value: $model.textSpeed, range: 0...100,
                      valueText: model.textSpeed == 0 ? "暂停" : "\(Int(model.textSpeed.rounded()))px/s")
            sliderRow("字号", value: $model.textFontSize, range: 9...24, valueText: "\(Int(model.textFontSize))pt")
            Text("文字沿曲线匀速走，陡处自动放慢横向移动。")
                .font(.system(size: 10)).foregroundStyle(muted)
            Text(textError ?? "短句和小说都会从头循环。TXT 仅保存在本机；天气文案是示例，不是实时预报。")
                .font(.system(size: 10)).foregroundStyle(textError == nil ? muted : .brown)
        }
    }

    private func useText(_ text: String) {
        model.textContent = text
        textError = nil
    }

    private var appearance: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                label("颜色")
                Spacer()
                ForEach(Ink.allCases, id: \.rawValue) { ink in
                    Button { model.ink = ink } label: {
                        Circle().fill(Color(nsColor: ink.color)).frame(width: 15, height: 15).padding(4)
                            .overlay(Circle().stroke(model.ink == ink ? darkInk.opacity(0.7) : darkInk.opacity(0.12), lineWidth: 1))
                    }.buttonStyle(.plain).help(ink.name).accessibilityLabel(ink.name)
                }
            }
            sliderRow("不透明度", value: $model.opacity, range: 0.15...1, valueText: "\(Int(model.opacity * 100))%")
            if model.curveMode == .line {
                sliderRow("线宽", value: $model.thickness, range: 0.6...3, valueText: String(format: "%.1f", model.thickness))
            }
            sliderRow("宽度", value: $model.width, range: 160...720, valueText: "\(Int(model.width))")
            sliderRow("高度", value: $model.height, range: 36...180, valueText: "\(Int(model.height))")
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Picker("行情", selection: $venue) {
                    Text("永续").tag(Venue.perpetual)
                    Text("现货").tag(Venue.spot)
                }.labelsHidden().frame(width: 70)
                TextField("如 QQQ、NVDA、BTCUSDT", text: $code).textFieldStyle(.roundedBorder)
                    .font(.system(size: 10)).onSubmit(addInstrument)
                Button("添加", action: addInstrument).controlSize(.small)
            }
            if let message = addError ?? model.error {
                Text(message).font(.system(size: 10)).foregroundStyle(.brown).lineLimit(2)
            } else {
                Text(model.series.map { $0.source + (model.curveMode == .line ? " · 呼吸表示行情更新中" : " · 字形走势随行情更新") } ?? "选择左侧标的，即可挂到桌面")
                    .font(.system(size: 9)).foregroundStyle(muted)
            }
            HStack {
                Text("拖动定位 · 双击隐藏 · 菜单栏退出").font(.system(size: 10)).foregroundStyle(muted)
                Spacer()
                Button("收起设置") { onDismiss() }.buttonStyle(.borderedProminent).controlSize(.small).keyboardShortcut(.cancelAction)
            }
        }
    }

    private func label(_ text: String) -> some View { Text(text).font(.system(size: 11)) }
    private func sliderRow(_ text: String, value: Binding<Double>, range: ClosedRange<Double>, valueText: String) -> some View {
        HStack(spacing: 16) {
            label(text).frame(width: 52, alignment: .leading)
            Slider(value: value, in: range).controlSize(.mini).accessibilityLabel(text)
            Text(valueText).font(.system(size: 10, design: .monospaced)).foregroundStyle(muted).frame(width: 48, alignment: .trailing)
        }
    }
    private func addInstrument() {
        do { try model.add(code, venue: venue); code = ""; addError = nil }
        catch { addError = error.localizedDescription }
    }
}

private struct CurvePreview: NSViewRepresentable {
    @ObservedObject var model: AppModel
    func makeNSView(context: Context) -> CurveView {
        let view = CurveView()
        view.allowsInteraction = false
        view.canvasBackground = NSColor(calibratedRed: 0.981, green: 0.976, blue: 0.965, alpha: 1)
        return view
    }
    func updateNSView(_ nsView: CurveView, context: Context) {
        nsView.configure(model: model, visible: true)
    }
    static func dismantleNSView(_ nsView: CurveView, coordinator: ()) { nsView.stopAnimation() }
}
