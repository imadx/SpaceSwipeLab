import AppKit
import ServiceManagement

final class MainWindowController: NSWindowController {
    private let engine: SpaceSwipeEngine

    private let permissionStatus = NSTextField(labelWithString: "")
    private let eventStatus = NSTextField(labelWithString: "Ready")
    private let overrideCheckbox = NSButton(
        checkboxWithTitle: "Override the native horizontal Space swipe",
        target: nil,
        action: nil
    )
    private let showMenuBarIconCheckbox = NSButton(
        checkboxWithTitle: "Show the menu-bar icon",
        target: nil,
        action: nil
    )
    private let launchAtLoginCheckbox = NSButton(
        checkboxWithTitle: "Launch at login",
        target: nil,
        action: nil
    )
    private let velocityPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private var permissionTimer: Timer?

    private let velocityOptions: [(name: String, value: Double)] = [
        ("Normal — 40", 40),
        ("Fast — 50", 50),
        ("Faster — 60", 60),
        ("Fastest — 80", 80),
        ("Effectively instant — 2000", 2_000)
    ]

    init(engine: SpaceSwipeEngine) {
        self.engine = engine

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 550),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Space Swipe Lab Settings"
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)
        configureUI()
        wireEngine()
        refreshPermissionStatus()
        startPermissionPolling()
    }

    required init?(coder: NSCoder) {
        nil
    }

    deinit {
        permissionTimer?.invalidate()
    }

    private func configureUI() {
        guard let contentView = window?.contentView else {
            return
        }

        let title = NSTextField(labelWithString: "Switch Spaces at your speed")
        title.font = .systemFont(ofSize: 22, weight: .semibold)

        let explanation = NSTextField(wrappingLabelWithString:
            "Grant Accessibility access, choose a transition speed, and enable the swipe override. Space Swipe Lab uses the finger count configured in System Settings → Trackpad → More Gestures; choose four fingers there for the intended experience."
        )
        explanation.textColor = .secondaryLabelColor

        permissionStatus.font = .systemFont(ofSize: 13, weight: .medium)

        let requestButton = NSButton(
            title: "Request Accessibility Access",
            target: self,
            action: #selector(requestPermission)
        )
        requestButton.bezelStyle = .rounded

        let settingsButton = NSButton(
            title: "Open Accessibility Settings",
            target: self,
            action: #selector(openAccessibilitySettings)
        )
        settingsButton.bezelStyle = .rounded

        let permissionButtons = NSStackView(views: [requestButton, settingsButton])
        permissionButtons.orientation = .horizontal
        permissionButtons.spacing = 8

        let permissionBox = makeSection(
            title: "1. Accessibility",
            views: [permissionStatus, permissionButtons]
        )

        velocityPopup.addItems(withTitles: velocityOptions.map(\.name))
        if let selectedVelocity = velocityOptions.firstIndex(where: {
            $0.value == AppPreferences.velocity
        }) {
            velocityPopup.selectItem(at: selectedVelocity)
        } else {
            velocityPopup.selectItem(at: velocityOptions.count - 1)
        }
        velocityPopup.target = self
        velocityPopup.action = #selector(velocityChanged)

        let previousButton = NSButton(
            title: "← Previous Space",
            target: self,
            action: #selector(switchPrevious)
        )
        previousButton.bezelStyle = .rounded

        let nextButton = NSButton(
            title: "Next Space →",
            target: self,
            action: #selector(switchNext)
        )
        nextButton.bezelStyle = .rounded

        let switchButtons = NSStackView(views: [previousButton, nextButton])
        switchButtons.orientation = .horizontal
        switchButtons.distribution = .fillEqually
        switchButtons.spacing = 10

        let directTestBox = makeSection(
            title: "2. Transition",
            views: [labeledRow(label: "Transition velocity", control: velocityPopup), switchButtons]
        )

        overrideCheckbox.target = self
        overrideCheckbox.action = #selector(overrideChanged)
        overrideCheckbox.state = engine.isOverrideEnabled ? .on : .off

        let safetyNote = NSTextField(wrappingLabelWithString:
            "The override is active only while Space Swipe Lab is running. Disabling it or quitting immediately restores the native gesture."
        )
        safetyNote.textColor = .secondaryLabelColor
        safetyNote.font = .systemFont(ofSize: 12)

        let overrideBox = makeSection(
            title: "3. Gesture",
            views: [overrideCheckbox, safetyNote]
        )

        showMenuBarIconCheckbox.target = self
        showMenuBarIconCheckbox.action = #selector(showMenuBarIconChanged)
        showMenuBarIconCheckbox.state = AppPreferences.showMenuBarIcon ? .on : .off

        launchAtLoginCheckbox.target = self
        launchAtLoginCheckbox.action = #selector(launchAtLoginChanged)
        launchAtLoginCheckbox.state = SMAppService.mainApp.status == .enabled ? .on : .off

        let backgroundNote = NSTextField(wrappingLabelWithString:
            "Closing this window keeps the utility running. Reopen it from the menu-bar icon, Dock, or Applications folder."
        )
        backgroundNote.textColor = .secondaryLabelColor
        backgroundNote.font = .systemFont(ofSize: 12)

        let behaviorBox = makeSection(
            title: "4. App behavior",
            views: [showMenuBarIconCheckbox, launchAtLoginCheckbox, backgroundNote]
        )

        eventStatus.textColor = .secondaryLabelColor
        eventStatus.lineBreakMode = .byTruncatingTail

        let rootStack = NSStackView(views: [
            title,
            explanation,
            permissionBox,
            directTestBox,
            overrideBox,
            behaviorBox,
            eventStatus
        ])
        rootStack.orientation = .vertical
        rootStack.alignment = .leading
        rootStack.spacing = 14
        rootStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(rootStack)
        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 22),
            rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -22),
            rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            rootStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -18),
            explanation.widthAnchor.constraint(equalTo: rootStack.widthAnchor),
            permissionBox.widthAnchor.constraint(equalTo: rootStack.widthAnchor),
            directTestBox.widthAnchor.constraint(equalTo: rootStack.widthAnchor),
            overrideBox.widthAnchor.constraint(equalTo: rootStack.widthAnchor),
            behaviorBox.widthAnchor.constraint(equalTo: rootStack.widthAnchor),
            eventStatus.widthAnchor.constraint(equalTo: rootStack.widthAnchor)
        ])
    }

    private func wireEngine() {
        engine.onSwitch = { [weak self] direction in
            DispatchQueue.main.async {
                self?.eventStatus.stringValue = "Sent: \(direction.displayName) at velocity \(Int(self?.engine.velocity ?? 0))"
            }
        }
    }

    private func startPermissionPolling() {
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {
            [weak self] _ in
            self?.refreshPermissionStatus()
        }
    }

    private func refreshPermissionStatus() {
        let trusted = SpaceSwipeEngine.isAccessibilityTrusted
        permissionStatus.stringValue = trusted
            ? "✓ Accessibility access granted"
            : "Accessibility access has not been granted"
        permissionStatus.textColor = trusted ? .systemGreen : .systemOrange

        if !trusted, engine.isOverrideEnabled {
            engine.stopOverride()
            AppPreferences.overrideEnabled = false
            overrideCheckbox.state = .off
            AppPreferences.notifyChanged()
        }
    }

    private func makeSection(title: String, views: [NSView]) -> NSBox {
        let box = NSBox()
        box.title = title
        box.boxType = .primary

        let stack = NSStackView(views: views)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 9
        stack.translatesAutoresizingMaskIntoConstraints = false

        box.contentView?.addSubview(stack)
        if let boxContent = box.contentView {
            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: boxContent.leadingAnchor, constant: 12),
                stack.trailingAnchor.constraint(equalTo: boxContent.trailingAnchor, constant: -12),
                stack.topAnchor.constraint(equalTo: boxContent.topAnchor, constant: 10),
                stack.bottomAnchor.constraint(equalTo: boxContent.bottomAnchor, constant: -10)
            ])
        }
        return box
    }

    private func labeledRow(label: String, control: NSView) -> NSStackView {
        let labelView = NSTextField(labelWithString: label)
        labelView.setContentHuggingPriority(.required, for: .horizontal)
        let stack = NSStackView(views: [labelView, control])
        stack.orientation = .horizontal
        stack.spacing = 10
        return stack
    }

    @objc private func requestPermission() {
        if SpaceSwipeEngine.requestAccessibilityPermission() {
            eventStatus.stringValue = "Accessibility access is already granted."
        } else {
            eventStatus.stringValue = "Approve Space Swipe Lab in System Settings, then return here."
        }
        refreshPermissionStatus()
    }

    @objc private func openAccessibilitySettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    @objc private func velocityChanged() {
        let index = velocityPopup.indexOfSelectedItem
        guard velocityOptions.indices.contains(index) else {
            return
        }
        engine.velocity = velocityOptions[index].value
        AppPreferences.velocity = engine.velocity
        AppPreferences.notifyChanged()
        eventStatus.stringValue = "Velocity set to \(Int(engine.velocity))."
    }

    @objc private func switchPrevious() {
        performDirectSwitch(.previous)
    }

    @objc private func switchNext() {
        performDirectSwitch(.next)
    }

    private func performDirectSwitch(_ direction: SpaceDirection) {
        do {
            try engine.postSpaceSwipe(direction)
        } catch {
            show(error: error)
        }
    }

    @objc private func overrideChanged() {
        if overrideCheckbox.state == .on {
            do {
                try engine.startOverride()
                AppPreferences.overrideEnabled = true
                eventStatus.stringValue = "Override active. Try a horizontal four-finger swipe."
            } catch {
                overrideCheckbox.state = .off
                AppPreferences.overrideEnabled = false
                show(error: error)
            }
        } else {
            engine.stopOverride()
            AppPreferences.overrideEnabled = false
            eventStatus.stringValue = "Override disabled; native Space swiping restored."
        }
        AppPreferences.notifyChanged()
    }

    @objc private func showMenuBarIconChanged() {
        AppPreferences.showMenuBarIcon = showMenuBarIconCheckbox.state == .on
        AppPreferences.notifyChanged()
        eventStatus.stringValue = AppPreferences.showMenuBarIcon
            ? "Menu-bar icon enabled."
            : "Menu-bar icon hidden. Reopen settings from the Dock or Applications folder."
    }

    @objc private func launchAtLoginChanged() {
        do {
            if launchAtLoginCheckbox.state == .on {
                try SMAppService.mainApp.register()
                eventStatus.stringValue = "Space Swipe Lab will launch when you sign in."
            } else {
                try SMAppService.mainApp.unregister()
                eventStatus.stringValue = "Launch at login disabled."
            }
        } catch {
            launchAtLoginCheckbox.state = SMAppService.mainApp.status == .enabled ? .on : .off
            show(error: error)
        }
    }

    private func show(error: Error) {
        eventStatus.stringValue = error.localizedDescription
        let alert = NSAlert(error: error)
        alert.runModal()
    }
}
