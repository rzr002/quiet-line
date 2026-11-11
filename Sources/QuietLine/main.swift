import AppKit
import SwiftUI
import QuietLineCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    var overlay: OverlayController!
    var settings: NSWindow!
    var statusItem: NSStatusItem!
    var visibilityItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        overlay = OverlayController(model: model)
        overlay.curve.onHide = { [weak self] in self?.model.visible = false }
        model.onVisualChange = { [weak self] in self?.updatePresentation() }
        buildSettings()
        buildMenus()
        model.start()
        showSettings()
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    private func buildSettings() {
        settings = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 700, height: 672),
                            styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        settings.title = "Quiet Line"
        settings.titleVisibility = .hidden
        settings.titlebarAppearsTransparent = true
        settings.isReleasedWhenClosed = false
        settings.backgroundColor = NSColor(calibratedRed: 0.965, green: 0.957, blue: 0.937, alpha: 1)
        settings.contentView = NSHostingView(rootView: SettingsView(model: model) { [weak self] in self?.settings.orderOut(nil) })
        settings.center()
    }
    private func buildMenus() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "waveform.path", accessibilityDescription: "Quiet Line 设置")
        statusItem.button?.image?.isTemplate = true
        let menu = NSMenu()
        let open = NSMenuItem(title: "打开设置…", action: #selector(showSettings), keyEquivalent: "")
        open.target = self
        menu.addItem(open)
        visibilityItem = NSMenuItem(title: "隐藏曲线", action: #selector(toggleVisibility), keyEquivalent: "")
        visibilityItem.target = self
        menu.addItem(visibilityItem)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "退出 Quiet Line", action: #selector(quitApp), keyEquivalent: "")
        quit.target = self
        menu.addItem(quit)
        statusItem.menu = menu
        let bar = NSMenu()
        let root = NSMenuItem()
        let appMenu = NSMenu(title: "Quiet Line")
        let openSettings = NSMenuItem(title: "打开设置…", action: #selector(showSettings), keyEquivalent: "")
        openSettings.target = self
        appMenu.addItem(openSettings)
        appMenu.addItem(.separator())
        let standardQuit = NSMenuItem(title: "退出 Quiet Line", action: #selector(quitApp), keyEquivalent: "q")
        standardQuit.target = self
        appMenu.addItem(standardQuit)
        root.submenu = appMenu
        bar.addItem(root)
        NSApp.mainMenu = bar
    }
    private func updatePresentation() {
        overlay.update(model: model)
        visibilityItem?.title = model.visible ? "隐藏曲线" : "显示曲线"
    }
    @objc func showSettings() {
        settings.deminiaturize(nil)
        settings.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    @objc func toggleVisibility() { model.visible.toggle() }
    @objc func quitApp() { NSApp.terminate(nil) }
}

if CommandLine.arguments.contains("--check-feeds") {
    Task {
        var failures = 0
        for instrument in Instrument.presets.prefix(3) {
            do {
                let series = try await FeedClient().fetch(instrument)
                let tick = try await FeedClient().latest(instrument)
                print("PASS \(instrument.symbol): \(series.points.count) history points; latest trade=\(tick.time); price=\(tick.price)")
            } catch { failures += 1; print("FAIL \(instrument.symbol): \(error.localizedDescription)") }
        }
        exit(failures == 0 ? 0 : 1)
    }
    RunLoop.main.run()
} else {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
