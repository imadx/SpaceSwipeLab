import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let engine = SpaceSwipeEngine()
    private var mainWindowController: MainWindowController?
    private var statusItem: NSStatusItem?
    private var overrideMenuItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        engine.velocity = AppPreferences.velocity
        if AppPreferences.overrideEnabled, SpaceSwipeEngine.isAccessibilityTrusted {
            try? engine.startOverride()
        }

        let controller = MainWindowController(engine: engine)
        mainWindowController = controller
        controller.showWindow(nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(preferencesDidChange),
            name: AppPreferences.didChangeNotification,
            object: nil
        )
        updateMenuBarVisibility()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        engine.stopOverride()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        showSettings()
        return true
    }

    func menuWillOpen(_ menu: NSMenu) {
        refreshOverrideMenuItem()
    }

    private func updateMenuBarVisibility() {
        if AppPreferences.showMenuBarIcon {
            if statusItem == nil {
                statusItem = makeStatusItem()
            }
        } else if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
            overrideMenuItem = nil
        }
    }

    private func makeStatusItem() -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(
            systemSymbolName: "rectangle.3.group",
            accessibilityDescription: "Space Swipe Lab"
        )
        item.button?.toolTip = "Space Swipe Lab"

        let menu = NSMenu()
        menu.delegate = self

        let overrideItem = NSMenuItem(
            title: "Enable Swipe Override",
            action: #selector(toggleOverrideFromMenu),
            keyEquivalent: ""
        )
        overrideItem.target = self
        overrideMenuItem = overrideItem
        menu.addItem(overrideItem)

        let settingsItem = NSMenuItem(
            title: "Open Settings…",
            action: #selector(showSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit Space Swipe Lab",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        item.menu = menu
        refreshOverrideMenuItem()
        return item
    }

    private func refreshOverrideMenuItem() {
        overrideMenuItem?.title = engine.isOverrideEnabled
            ? "Disable Swipe Override"
            : "Enable Swipe Override"
        overrideMenuItem?.state = engine.isOverrideEnabled ? .on : .off
    }

    @objc private func toggleOverrideFromMenu() {
        if engine.isOverrideEnabled {
            engine.stopOverride()
            AppPreferences.overrideEnabled = false
        } else {
            do {
                try engine.startOverride()
                AppPreferences.overrideEnabled = true
            } catch {
                showSettings()
                NSAlert(error: error).runModal()
            }
        }
        AppPreferences.notifyChanged()
        refreshOverrideMenuItem()
    }

    @objc private func showSettings() {
        mainWindowController?.showWindow(nil)
        mainWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func preferencesDidChange() {
        engine.velocity = AppPreferences.velocity
        updateMenuBarVisibility()
        refreshOverrideMenuItem()
    }
}
