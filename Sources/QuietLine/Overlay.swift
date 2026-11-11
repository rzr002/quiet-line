import AppKit
import QuietLineCore

final class CurvePanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class CurveView: NSView {
    private(set) var points: [CurvePoint] = []
    var ink = NSColor.gray
    var opacity = 0.72
    var thickness = 1.3
    var onHide: (() -> Void)?
    var allowsInteraction = true
    var canvasBackground: NSColor?
    private var mode: CurveMode = .line
    private var text = ""
    private var fontSize = 14.0
    private var textSpeed = 18.0
    private var glyphs: [String] = []
    private var flow = TextCurveFlow(glyphWidths: [])
    private var font = NSFont.systemFont(ofSize: 14)
    private var textHeight = 18.0
    private var textOffset = 0.0
    private var lastAnimationAt: Date?
    private var visible = false
    private var lastPointAt: Date?
    private var receivedAt: Date?
    private var animationTimer: Timer?
    private var transitionFrom: CurvePoint?
    private var transitionBegan = Date.distantPast
    private var dragStart: NSPoint?
    private var dragOrigin: NSPoint?
    override var isOpaque: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    func configure(model: AppModel, visible: Bool) {
        ink = model.ink.color
        opacity = model.opacity
        thickness = model.thickness
        mode = model.curveMode
        textSpeed = model.textSpeed
        if text != model.textContent || fontSize != model.textFontSize {
            text = model.textContent
            fontSize = model.textFontSize
            font = NSFont.systemFont(ofSize: fontSize)
            glyphs = TextCurveContent.glyphs(from: text)
            var measured: [String: Double] = [:]
            let attributes: [NSAttributedString.Key: Any] = [.font: font]
            flow = TextCurveFlow(glyphWidths: glyphs.map { glyph in
                if let width = measured[glyph] { return width }
                let size = (glyph as NSString).size(withAttributes: attributes)
                // Upright glyphs need room on steep segments as well as on horizontal ones.
                let width = hypot(size.width + 0.8, size.height)
                measured[glyph] = width
                return width
            })
            textHeight = ("国Ag" as NSString).size(withAttributes: attributes).height
            textOffset = 0
        }
        updateSeries(model.series, receivedAt: model.fetchedAt, visible: visible)
    }

    func updateSeries(_ series: PriceSeries?, receivedAt: Date?, visible: Bool) {
        let next = CurveGeometry.normalize(series?.points.map(\.price) ?? [])
        let previous = displayedEndpoint(at: Date())
        // Only interpolate the real endpoint after a price change. Never invent price ticks.
        if let previous, let last = next.last, points.count == next.count, last != points.last {
            transitionFrom = previous
            transitionBegan = Date()
        }
        points = next
        self.lastPointAt = series?.points.last?.time
        self.receivedAt = receivedAt
        self.visible = visible
        if shouldAnimate {
            if animationTimer == nil {
                lastAnimationAt = Date()
                let timer = Timer(timeInterval: 1.0 / 24, repeats: true) { [weak self] _ in
                    MainActor.assumeIsolated { self?.tick() }
                }
                animationTimer = timer
                RunLoop.main.add(timer, forMode: .common)
            }
        } else { stopAnimation() }
        needsDisplay = true
    }

    private var scrolling: Bool { mode == .text && textSpeed > 0 && !glyphs.isEmpty && points.count >= 2 }
    private var shouldAnimate: Bool {
        visible && (scrolling || isTransitioning || (mode == .line && updating(at: Date())))
    }
    private var isTransitioning: Bool { transitionFrom != nil && Date().timeIntervalSince(transitionBegan) < 0.55 }
    private func updating(at date: Date) -> Bool {
        CurveActivity.isUpdating(lastPointAt: lastPointAt, receivedAt: receivedAt, now: date)
    }
    private func displayedEndpoint(at date: Date) -> CurvePoint? {
        guard let target = points.last else { return nil }
        guard let from = transitionFrom else { return target }
        let fraction = min(1, max(0, date.timeIntervalSince(transitionBegan) / 0.55))
        let eased = 1 - pow(1 - fraction, 3)
        return CurvePoint(x: target.x, y: from.y + (target.y - from.y) * eased)
    }
    private func tick() {
        let now = Date()
        // Keep a hidden settings preview at its reading position without scheduling redraws.
        guard window?.isVisible != false else { lastAnimationAt = now; return }
        if scrolling, let lastAnimationAt, flow.cycleWidth > 0 {
            textOffset = (textOffset + max(0, now.timeIntervalSince(lastAnimationAt)) * textSpeed)
                .truncatingRemainder(dividingBy: flow.cycleWidth)
        }
        lastAnimationAt = now
        needsDisplay = true
        if !shouldAnimate { stopAnimation() }
    }
    func stopAnimation() { animationTimer?.invalidate(); animationTimer = nil; lastAnimationAt = nil }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        if let canvasBackground {
            context.setFillColor(canvasBackground.cgColor)
            context.fill(bounds)
        } else { context.clear(bounds) }
        guard points.count >= 2 else { return }
        if mode == .text { drawText(); return }
        let inset = 6.0
        let now = Date()
        let endpoint = displayedEndpoint(at: now)!
        let path = CGMutablePath()
        for (index, point) in points.enumerated() {
            let displayed = index == points.count - 1 ? endpoint : point
            let position = CGPoint(x: inset + displayed.x * max(0, bounds.width - inset * 2),
                                   y: inset + displayed.y * max(0, bounds.height - inset * 2))
            if index == 0 { path.move(to: position) } else { path.addLine(to: position) }
        }
        context.setShouldAntialias(true)
        context.setStrokeColor(ink.withAlphaComponent(opacity).cgColor)
        context.setLineWidth(thickness)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.addPath(path)
        context.strokePath()
        let end = CGPoint(x: inset + endpoint.x * max(0, bounds.width - inset * 2),
                          y: inset + endpoint.y * max(0, bounds.height - inset * 2))
        if updating(at: now) {
            let breath = (sin(now.timeIntervalSinceReferenceDate * .pi * 2 / 2.6) + 1) / 2
            let radius = 2.8 + breath * 1.4
            context.setFillColor(ink.withAlphaComponent(opacity * (0.08 + breath * 0.10)).cgColor)
            context.fillEllipse(in: CGRect(x: end.x - radius, y: end.y - radius, width: radius * 2, height: radius * 2))
        }
        let radius = max(1.65, thickness * 0.85)
        context.setFillColor(ink.withAlphaComponent(opacity).cgColor)
        context.fillEllipse(in: CGRect(x: end.x - radius, y: end.y - radius, width: radius * 2, height: radius * 2))
    }

    private func drawText() {
        var displayed = points
        if let endpoint = displayedEndpoint(at: Date()) { displayed[displayed.count - 1] = endpoint }
        let positions = flow.placements(points: displayed, width: bounds.width, height: bounds.height,
                                        inset: max(6, textHeight / 2 + 2), offset: textOffset, alongCurve: true)
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: ink.withAlphaComponent(opacity)]
        for position in positions {
            (glyphs[position.index] as NSString).draw(at: NSPoint(x: position.x, y: position.y - textHeight / 2),
                                                     withAttributes: attributes)
        }
    }

    override func mouseDown(with event: NSEvent) {
        guard allowsInteraction else { return }
        if event.clickCount == 2 { onHide?(); return }
        dragStart = NSEvent.mouseLocation
        dragOrigin = window?.frame.origin
    }
    override func mouseDragged(with event: NSEvent) {
        guard allowsInteraction, let start = dragStart, let origin = dragOrigin else { return }
        let cursor = NSEvent.mouseLocation
        window?.setFrameOrigin(NSPoint(x: origin.x + cursor.x - start.x, y: origin.y + cursor.y - start.y))
    }
    override func mouseUp(with event: NSEvent) {
        guard allowsInteraction else { return }
        defer { dragStart = nil; dragOrigin = nil }
        if let origin = window?.frame.origin {
            UserDefaults.standard.set(NSStringFromPoint(origin), forKey: "overlayOrigin")
        }
    }
}

@MainActor
final class OverlayController {
    let panel: CurvePanel
    let curve: CurveView

    init(model: AppModel) {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        var origin = NSPoint(x: screen.maxX - model.width - 36, y: screen.maxY - model.height - 80)
        if let saved = UserDefaults.standard.string(forKey: "overlayOrigin") {
            let point = NSPointFromString(saved)
            let restored = NSRect(origin: point, size: NSSize(width: model.width, height: model.height))
            if NSScreen.screens.contains(where: { $0.visibleFrame.contains(restored) }) { origin = point }
        }
        panel = CurvePanel(contentRect: NSRect(origin: origin, size: NSSize(width: model.width, height: model.height)),
                           styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.title = ""
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.isExcludedFromWindowsMenu = true
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .none
        curve = CurveView(frame: NSRect(origin: .zero, size: panel.frame.size))
        curve.autoresizingMask = [.width, .height]
        panel.contentView = curve
    }

    func update(model: AppModel) {
        let size = NSSize(width: model.width, height: model.height)
        if panel.frame.size != size {
            var frame = panel.frame
            frame.origin.y += frame.height - size.height
            frame.size = size
            if let screen = NSScreen.screens.first(where: { $0.visibleFrame.intersects(frame) })?.visibleFrame {
                frame.origin.x = max(screen.minX, min(frame.minX, screen.maxX - frame.width))
                frame.origin.y = max(screen.minY, min(frame.minY, screen.maxY - frame.height))
            }
            panel.setFrame(frame, display: false)
        }
        curve.configure(model: model, visible: model.visible)
        panel.ignoresMouseEvents = false
        if model.visible && curve.points.count >= 2 { panel.orderFrontRegardless() } else { panel.orderOut(nil) }
    }
}
