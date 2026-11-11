import AppKit
import Combine
import QuietLineCore

enum Ink: Int, CaseIterable {
    case graphite, chalk, sage, amber
    var name: String { switch self { case .graphite: "石墨"; case .chalk: "白色"; case .sage: "苔绿"; case .amber: "琥珀" } }
    var color: NSColor {
        switch self {
        case .graphite: NSColor(calibratedWhite: 0.34, alpha: 1)
        case .chalk: .white
        case .sage: NSColor(calibratedRed: 0.35, green: 0.49, blue: 0.43, alpha: 1)
        case .amber: NSColor(calibratedRed: 0.70, green: 0.48, blue: 0.24, alpha: 1)
        }
    }
}

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var selected: Instrument
    @Published private(set) var instruments: [Instrument]
    @Published private(set) var series: PriceSeries? { didSet { onVisualChange?() } }
    @Published private(set) var loading = false
    @Published private(set) var error: String?
    @Published private(set) var fetchedAt: Date? { didSet { onVisualChange?() } }
    @Published var range: HistoryRange = .hour { didSet { if ready { defaults.set(range.rawValue, forKey: "range"); resetFeed() } } }
    @Published var visible = true { didSet { updatePreferences(); if visible { refresh() } } }
    @Published var width: Double = 360 { didSet { updatePreferences() } }
    @Published var height: Double = 100 { didSet { updatePreferences() } }
    @Published var opacity: Double = 0.72 { didSet { updatePreferences() } }
    @Published var thickness: Double = 1.3 { didSet { updatePreferences() } }
    @Published var ink: Ink = .graphite { didSet { updatePreferences() } }
    @Published var curveMode: CurveMode = .line { didSet { updatePreferences() } }
    @Published var textContent = "行到水穷处，坐看云起时。 " {
        didSet {
            guard ready else { return }
            defaults.set(textContent, forKey: "textContent")
            onVisualChange?()
        }
    }
    @Published var textSpeed: Double = 18 { didSet { updatePreferences() } }
    @Published var textFontSize: Double = 14 { didSet { updatePreferences() } }
    var onVisualChange: (() -> Void)?
    private var fetchTask: Task<Void, Never>?
    private var timer: Task<Void, Never>?
    private var requestID = UUID()
    private var failedAt: Date?
    private let defaults = UserDefaults.standard
    private var ready = false

    init() {
        let custom = defaults.data(forKey: "cryptoInstruments")
            .flatMap { try? JSONDecoder().decode([Instrument].self, from: $0) } ?? []
        let options = Instrument.presets + custom.filter { item in !Instrument.presets.contains(where: { $0.id == item.id }) }
        let savedSelection = defaults.string(forKey: "cryptoSelected")
        instruments = options
        selected = options.first(where: { $0.id == savedSelection }) ?? Instrument.presets[0]
        range = HistoryRange(rawValue: defaults.integer(forKey: "range")) ?? .hour
        if defaults.object(forKey: "width") != nil {
            width = min(720, max(160, defaults.double(forKey: "width")))
            height = min(180, max(36, defaults.double(forKey: "height")))
            opacity = min(1, max(0.15, defaults.double(forKey: "opacity")))
            thickness = min(3, max(0.6, defaults.double(forKey: "thickness")))
            ink = Ink(rawValue: defaults.integer(forKey: "ink")) ?? .graphite
        }
        curveMode = CurveMode(rawValue: defaults.string(forKey: "curveMode") ?? "line") ?? .line
        textContent = defaults.string(forKey: "textContent") ?? textContent
        if defaults.object(forKey: "textSpeed") != nil { textSpeed = min(100, max(0, defaults.double(forKey: "textSpeed"))) }
        if defaults.object(forKey: "textFontSize") != nil { textFontSize = min(24, max(9, defaults.double(forKey: "textFontSize"))) }
        ready = true
    }

    func start() {
        refresh()
        timer = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(2)) } catch { break }
                guard let self else { break }
                if self.visible && (self.failedAt.map { Date().timeIntervalSince($0) >= 10 } ?? true) {
                    self.load(history: self.series == nil)
                }
            }
        }
    }

    func select(_ instrument: Instrument) {
        guard selected.id != instrument.id else { visible = true; return }
        selected = instrument
        defaults.set(instrument.id, forKey: "cryptoSelected")
        resetFeed()
        visible = true
    }

    func add(_ input: String, venue: Venue? = nil) throws {
        let instrument = try Instrument.custom(input, venue: venue)
        let existing = instruments.first(where: { $0.id == instrument.id })
        if existing == nil {
            instruments.append(instrument)
            let custom = instruments.filter { item in !Instrument.presets.contains(where: { $0.id == item.id }) }
            defaults.set(try JSONEncoder().encode(custom), forKey: "cryptoInstruments")
        }
        select(existing ?? instrument)
    }

    private func resetFeed() {
        fetchTask?.cancel()
        fetchTask = nil
        requestID = UUID()
        series = nil
        fetchedAt = nil
        error = nil
        failedAt = nil
        load(history: true)
    }
    func refresh() { load(history: true) }

    private func load(history: Bool) {
        guard fetchTask == nil else { return }
        let instrument = selected
        let selectedRange = range
        let token = UUID()
        requestID = token
        loading = true
        fetchTask = Task { [weak self] in
            do {
                let updated: PriceSeries
                if history {
                    updated = try await FeedClient().fetch(instrument, range: selectedRange)
                } else {
                    let tick = try await FeedClient().latest(instrument)
                    guard let self, self.requestID == token, let current = self.series else { return }
                    updated = current.applying(tick, bucketSeconds: selectedRange.bucketSeconds, limit: selectedRange.limit)
                }
                guard let self, !Task.isCancelled, self.requestID == token else { return }
                self.series = updated
                self.fetchedAt = Date()
                self.error = nil
                self.failedAt = nil
            } catch {
                guard let self, !Task.isCancelled, self.requestID == token else { return }
                self.series = nil
                self.error = error.localizedDescription
                self.failedAt = Date()
            }
            guard let self, self.requestID == token else { return }
            self.loading = false
            self.fetchTask = nil
        }
    }

    private func updatePreferences() {
        guard ready else { return }
        defaults.set(width, forKey: "width"); defaults.set(height, forKey: "height")
        defaults.set(opacity, forKey: "opacity"); defaults.set(thickness, forKey: "thickness")
        defaults.set(ink.rawValue, forKey: "ink")
        defaults.set(curveMode.rawValue, forKey: "curveMode")
        defaults.set(textSpeed, forKey: "textSpeed")
        defaults.set(textFontSize, forKey: "textFontSize")
        onVisualChange?()
    }
}
