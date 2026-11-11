import SwiftUI
import QuietLineCore

private let paper = Color(red: 0.965, green: 0.957, blue: 0.937)
private let darkInk = Color(red: 0.20, green: 0.24, blue: 0.22)
private let muted = Color(red: 0.47, green: 0.49, blue: 0.45)

struct SettingsView: View {
    @ObservedObject var model: AppModel
    let onDismiss: () -> Void
    @State private var code = ""
    @State private var venue: Venue = .perpetual
    @State private var addError: String?

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Rectangle().fill(darkInk.opacity(0.10)).frame(width: 1)
            VStack(alignment: .leading, spacing: 22) {
                header
                preview
                appearance
                interactions
                Spacer(minLength: 0)
                footer
            }
            .padding(.horizontal, 28).padding(.top, 28).padding(.bottom, 22)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: 700, height: 672)
        .background(paper).foregroundStyle(darkInk).tint(darkInk).preferredColorScheme(.light)
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
                Text("01 / DEMO").font(.system(size: 9, design: .monospaced)).foregroundStyle(muted)
            }
            Text("一条曲线，一个呼吸的点。其余都藏起来。")
                .font(.system(size: 11)).foregroundStyle(muted)
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
                CurvePreview(values: model.series?.points.map(\.price) ?? [],
                             color: Color(nsColor: model.ink.color), opacity: model.opacity, width: model.thickness,
                             updating: CurveActivity.isUpdating(lastPointAt: model.series?.points.last?.time,
                                                               receivedAt: model.fetchedAt, now: Date()))
                if model.series == nil {
                    Text(model.loading ? "正在获取曲线…" : "等待可用行情")
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

    private var appearance: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                label("线条")
                Spacer()
                ForEach(Ink.allCases, id: \.rawValue) { ink in
                    Button { model.ink = ink } label: {
                        Circle().fill(Color(nsColor: ink.color)).frame(width: 15, height: 15).padding(4)
                            .overlay(Circle().stroke(model.ink == ink ? darkInk.opacity(0.7) : darkInk.opacity(0.12), lineWidth: 1))
                    }.buttonStyle(.plain).help(ink.name).accessibilityLabel(ink.name)
                }
            }
            sliderRow("不透明度", value: $model.opacity, range: 0.15...1, valueText: "\(Int(model.opacity * 100))%")
            sliderRow("线宽", value: $model.thickness, range: 0.6...3, valueText: String(format: "%.1f", model.thickness))
            sliderRow("宽度", value: $model.width, range: 160...720, valueText: "\(Int(model.width))")
            sliderRow("高度", value: $model.height, range: 36...180, valueText: "\(Int(model.height))")
        }
    }

    private var interactions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle().fill(darkInk.opacity(0.1)).frame(height: 0.6)
            HStack {
                Button(model.visible ? "隐藏曲线" : "显示曲线") { model.visible.toggle() }.controlSize(.small)
                Spacer()
                Text(model.visible ? "正在桌面显示" : "已隐藏").foregroundStyle(muted)
            }.font(.system(size: 11))
            Text("单击拖动，双击隐藏。回来时在这里点「显示曲线」。")
                .font(.system(size: 10)).foregroundStyle(muted)
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
                Text(model.series.map { $0.source + " · 呼吸表示行情更新中" } ?? "选择左侧标的，即可挂到桌面")
                    .font(.system(size: 9)).foregroundStyle(muted)
            }
            HStack {
                Text("菜单栏曲线图标 → 设置 / 退出").font(.system(size: 10)).foregroundStyle(muted)
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
            Text(valueText).font(.system(size: 10, design: .monospaced)).foregroundStyle(muted).frame(width: 35, alignment: .trailing)
        }
    }
    private func addInstrument() {
        do { try model.add(code, venue: venue); code = ""; addError = nil }
        catch { addError = error.localizedDescription }
    }
}

private struct CurvePreview: View {
    let values: [Double]
    let color: Color
    let opacity: Double
    let width: Double
    let updating: Bool
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !updating)) { timeline in
          Canvas { context, size in
            let points = CurveGeometry.normalize(values)
            guard !points.isEmpty else { return }
            var path = Path()
            for (index, p) in points.enumerated() {
                let point = CGPoint(x: 2 + p.x * (size.width - 4), y: 2 + (1 - p.y) * (size.height - 4))
                if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            context.stroke(path, with: .color(color.opacity(opacity)), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
            if let last = points.last {
                let end = CGPoint(x: 2 + last.x * (size.width - 4), y: 2 + (1 - last.y) * (size.height - 4))
                if updating {
                    let breath = (sin(timeline.date.timeIntervalSinceReferenceDate * .pi * 2 / 2.6) + 1) / 2
                    let radius = 2.8 + breath * 1.4
                    context.fill(Path(ellipseIn: CGRect(x: end.x - radius, y: end.y - radius, width: radius * 2, height: radius * 2)),
                                 with: .color(color.opacity(opacity * (0.08 + breath * 0.10))))
                }
                let radius = max(1.65, width * 0.85)
                context.fill(Path(ellipseIn: CGRect(x: end.x - radius, y: end.y - radius, width: radius * 2, height: radius * 2)),
                             with: .color(color.opacity(opacity)))
            }
          }
        }.accessibilityLabel("曲线预览")
    }
}
