import SwiftUI
import AppKit

func tsLog(_ message: String) {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    let timeString = formatter.string(from: Date())
    // print("[\(timeString)] \(message)")
}

@main
struct ScreenBrushApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var windows: [OverlayWindow] = []
    var drawingModeState = DrawingModeState()
    var keyMonitorLocal: Any?
    var keyMonitorGlobal: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        tsLog("Application did finish launching")

        // --- Utility/Accessory App Activation Policy ---
        NSApp.setActivationPolicy(.accessory)
        tsLog("Application activation policy set to .accessory")

        createOverlayWindows()
        addKeyEventMonitors()
        tsLog("Overlay windows at launch: \(windowsDescription())")

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(spaceDidChange),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
    }

    func createOverlayWindows() {
        tsLog("Creating overlay windows for all screens...")
        let screens = NSScreen.screens
        tsLog("NSScreen.screens: \(screens)")
        for screen in screens {
            let rect = screen.frame
            let window = OverlayWindow(
                contentRect: rect,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.isOpaque = false
            window.backgroundColor = .clear
            window.level = .mainMenu + 1
            window.collectionBehavior = [
                .canJoinAllSpaces,
                .fullScreenAuxiliary,
                .ignoresCycle
            ]
            window.ignoresMouseEvents = false // Start in drawing mode
            window.contentView = NSHostingView(rootView: DrawingCanvas().environmentObject(drawingModeState))
            window.orderFrontRegardless()
            tsLog("Created overlay window: \(window) for screen: \(screen) [frame: \(rect)]")
            windows.append(window)
        }
        tsLog("All overlay windows after creation: \(windowsDescription())")
    }

    func addKeyEventMonitors() {
        tsLog("Adding key event monitors")
        keyMonitorLocal = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            tsLog("Local key event intercepted: \(event)")
            self?.handleKeyEvent(event, source: "local")
            // In accessory mode, local events only fire when overlay is key
            return event // Pass through to allow other apps to receive as well
        }
        keyMonitorGlobal = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            tsLog("Global key event intercepted: \(event)")
            self?.handleKeyEvent(event, source: "global")
        }
        tsLog("Key monitors added: local = \(keyMonitorLocal != nil), global = \(keyMonitorGlobal != nil)")
    }

    @objc func spaceDidChange(_ notification: Notification) {
        tsLog("Space/Desktop/Fullscreen changed. Re-asserting window order and visibility states:")
        for window in windows {
            tsLog("Before: isVisible=\(window.isVisible), isKeyWindow=\(window.isKeyWindow), isOnActiveSpace=\(window.isOnActiveSpace)")
            window.orderFrontRegardless()
            tsLog("After:  isVisible=\(window.isVisible), isKeyWindow=\(window.isKeyWindow), isOnActiveSpace=\(window.isOnActiveSpace)")
        }
        tsLog("All overlay windows re-asserted.")
    }

    func windowsDescription() -> String {
        windows.map { w in
            let addr = Unmanaged.passUnretained(w).toOpaque()
            return "#\(windows.firstIndex(of: w) ?? -1):\(addr)"
        }.joined(separator: ", ")
    }

    @MainActor
    func handleKeyEvent(_ event: NSEvent, source: String) {
        let isOption = event.modifierFlags.contains(.option)
        let isShift = event.modifierFlags.contains(.shift)
        let char = event.charactersIgnoringModifiers?.lowercased()
        if isOption && isShift && char == "t" {
            tsLog("Toggle Drawing Mode shortcut detected (Option+Shift+T)")
            toggleDrawingMode()
        } else if isOption && char == "z" {
            tsLog("Undo shortcut detected")
            NotificationCenter.default.post(name: .undoStroke, object: nil)
        } else if event.keyCode == 51 {
            tsLog("Clear All shortcut detected")
            NotificationCenter.default.post(name: .clearAllStrokes, object: nil)
        }
    }

    @MainActor
    func toggleDrawingMode() {
        tsLog("Toggling drawing mode")
        drawingModeState.drawingMode.toggle()
        for window in windows {
            tsLog("Updating window: \(window) to \(drawingModeState.drawingMode ? "drawing mode" : "click-through mode")")
            window.ignoresMouseEvents = !drawingModeState.drawingMode
            if drawingModeState.drawingMode {
                window.orderFrontRegardless()
            }
        }
    }
}
