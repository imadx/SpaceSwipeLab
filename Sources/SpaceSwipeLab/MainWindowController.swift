import AppKit
import ServiceManagement

final class MainWindowController: NSWindowController {
    private let engine: SpaceSwipeEngine

    private let permissionIcon = NSImageView()
    private let permissionTitle = NSTextField(labelWithString: "")
    private let permissionDetail = NSTextField(wrappingLabelWithString: "")
    private let permissionButton = NSButton()
    private let overrideSwitch = NSSwitch()
    private let speedControl = NSSegmentedControl(
        labels: ["Normal", "Fast", "Instant"],
        trackingMode: .selectOne,
        target: nil,
        action: nil
    )
    private let speedCaption = NSTextField(labelWithString: "")
    private let eventStatus = NSTextField(labelWithString: "Ready")
    private let optionsButton = NSButton()
    private var permissionTimer: Timer?

    private let speedOptions: [(caption: String, value: Double)] = [
        ("macOS-like motion", 40),
        ("short, responsive motion", 80),
        ("near-instant switching", 2_000)
    ]

    init(engine: SpaceSwipeEngine) {
        self.engine = engine

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Space Swipe Lab"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
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

        let header = makeHeader()
        let statusCard = makeStatusCard()
        let transitionCard = makeTransitionCard()
        let trackpadRow = makeTrackpadRow()

        eventStatus.font = .systemFont(ofSize: 12)
        eventStatus.textColor = .tertiaryLabelColor
        eventStatus.alignment = .center
        eventStatus.lineBreakMode = .byTruncatingTail

        let root = NSStackView(views: [header, statusCard, transitionCard, trackpadRow, eventStatus])
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 14
        root.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 26),
            root.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -26),
            root.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 48),
            root.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20),
            header.widthAnchor.constraint(equalTo: root.widthAnchor),
            statusCard.widthAnchor.constraint(equalTo: root.widthAnchor),
            transitionCard.widthAnchor.constraint(equalTo: root.widthAnchor),
            trackpadRow.widthAnchor.constraint(equalTo: root.widthAnchor),
            eventStatus.widthAnchor.constraint(equalTo: root.widthAnchor)
        ])
    }

    private func makeHeader() -> NSView {
        let icon = NSImageView(image: NSApp.applicationIconImage)
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 54),
            icon.heightAnchor.constraint(equalToConstant: 54)
        ])

        let title = NSTextField(labelWithString: "Space Swipe Lab")
        title.font = .systemFont(ofSize: 23, weight: .semibold)

        let subtitle = NSTextField(labelWithString: "Move between desktops at your pace")
        subtitle.font = .systemFont(ofSize: 13)
        subtitle.textColor = .secondaryLabelColor

        let labels = NSStackView(views: [title, subtitle])
        labels.orientation = .vertical
        labels.alignment = .leading
        labels.spacing = 2

        optionsButton.image = NSImage(
            systemSymbolName: "ellipsis.circle",
            accessibilityDescription: "App options"
        )
        optionsButton.imagePosition = .imageOnly
        optionsButton.bezelStyle = .accessoryBarAction
        optionsButton.isBordered = false
        optionsButton.contentTintColor = .secondaryLabelColor
        optionsButton.target = self
        optionsButton.action = #selector(showOptionsMenu)
        optionsButton.toolTip = "App options"
        optionsButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            optionsButton.widthAnchor.constraint(equalToConstant: 32),
            optionsButton.heightAnchor.constraint(equalToConstant: 32)
        ])

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let header = NSStackView(views: [icon, labels, spacer, optionsButton])
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 12
        return header
    }

    private func makeStatusCard() -> NSView {
        permissionIcon.imageScaling = .scaleProportionallyUpOrDown
        permissionIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            permissionIcon.widthAnchor.constraint(equalToConstant: 30),
            permissionIcon.heightAnchor.constraint(equalToConstant: 30)
        ])

        permissionTitle.font = .systemFont(ofSize: 15, weight: .semibold)
        permissionDetail.font = .systemFont(ofSize: 12)
        permissionDetail.textColor = .secondaryLabelColor
        permissionDetail.maximumNumberOfLines = 2

        let labels = NSStackView(views: [permissionTitle, permissionDetail])
        labels.orientation = .vertical
        labels.alignment = .leading
        labels.spacing = 3

        permissionButton.title = "Allow Access"
        permissionButton.bezelStyle = .rounded
        permissionButton.controlSize = .small
        permissionButton.target = self
        permissionButton.action = #selector(requestPermission)

        overrideSwitch.target = self
        overrideSwitch.action = #selector(overrideChanged)
        overrideSwitch.state = engine.isOverrideEnabled ? .on : .off
        overrideSwitch.toolTip = "Enable or disable faster Space switching"

        let trailing = NSStackView(views: [permissionButton, overrideSwitch])
        trailing.orientation = .horizontal
        trailing.alignment = .centerY
        trailing.spacing = 10

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let row = NSStackView(views: [permissionIcon, labels, spacer, trailing])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12
        return makeCard(containing: row, padding: 16)
    }

    private func makeTransitionCard() -> NSView {
        let title = NSTextField(labelWithString: "Transition speed")
        title.font = .systemFont(ofSize: 15, weight: .semibold)

        speedControl.target = self
        speedControl.action = #selector(speedChanged)
        speedControl.segmentStyle = .automatic
        speedControl.translatesAutoresizingMaskIntoConstraints = false

        let selectedIndex = speedOptions.enumerated().min(by: {
            abs($0.element.value - AppPreferences.velocity)
                < abs($1.element.value - AppPreferences.velocity)
        })?.offset ?? 2
        speedControl.selectedSegment = selectedIndex

        speedCaption.font = .systemFont(ofSize: 12)
        speedCaption.textColor = .secondaryLabelColor
        speedCaption.alignment = .center
        updateSpeedCaption()

        let previousButton = makeTestButton(
            title: "Previous",
            symbol: "arrow.left",
            action: #selector(switchPrevious)
        )
        let nextButton = makeTestButton(
            title: "Next",
            symbol: "arrow.right",
            action: #selector(switchNext)
        )

        let buttonSpacer = NSView()
        buttonSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let testRow = NSStackView(views: [previousButton, buttonSpacer, nextButton])
        testRow.orientation = .horizontal
        testRow.alignment = .centerY
        testRow.spacing = 8

        let stack = NSStackView(views: [title, speedControl, speedCaption, testRow])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 11

        NSLayoutConstraint.activate([
            speedControl.widthAnchor.constraint(equalToConstant: 430),
            testRow.widthAnchor.constraint(equalTo: speedControl.widthAnchor)
        ])
        return makeCard(containing: stack, padding: 16)
    }

    private func makeTrackpadRow() -> NSView {
        let symbol = NSImageView(image: NSImage(
            systemSymbolName: "hand.draw",
            accessibilityDescription: nil
        ) ?? NSImage())
        symbol.contentTintColor = .secondaryLabelColor
        symbol.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            symbol.widthAnchor.constraint(equalToConstant: 22),
            symbol.heightAnchor.constraint(equalToConstant: 22)
        ])

        let label = NSTextField(labelWithString: "Use four fingers for the clearest gesture")
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabelColor

        let button = NSButton(title: "Trackpad Settings", target: self, action: #selector(openTrackpadSettings))
        button.bezelStyle = .inline
        button.isBordered = false
        button.contentTintColor = .controlAccentColor

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let row = NSStackView(views: [symbol, label, spacer, button])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 9
        return row
    }

    private func makeCard(containing view: NSView, padding: CGFloat) -> NSBox {
        let card = NSBox()
        card.boxType = .custom
        card.borderWidth = 0
        card.cornerRadius = 13
        card.fillColor = .controlBackgroundColor

        view.translatesAutoresizingMaskIntoConstraints = false
        card.contentView?.addSubview(view)
        if let content = card.contentView {
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: padding),
                view.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -padding),
                view.topAnchor.constraint(equalTo: content.topAnchor, constant: padding),
                view.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -padding)
            ])
        }
        return card
    }

    private func makeTestButton(title: String, symbol: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        button.imagePosition = symbol == "arrow.left" ? .imageLeading : .imageTrailing
        button.bezelStyle = .inline
        button.isBordered = false
        button.contentTintColor = .secondaryLabelColor
        return button
    }

    private func wireEngine() {
        engine.onSwitch = { [weak self] direction in
            DispatchQueue.main.async {
                self?.eventStatus.stringValue = "Switched to the \(direction == .next ? "next" : "previous") desktop"
            }
        }
        engine.onBoundary = { [weak self] direction in
            DispatchQueue.main.async {
                self?.eventStatus.stringValue = direction == .previous
                    ? "Already at the first desktop — keeping the native edge gesture"
                    : "Already at the last desktop — keeping the native edge gesture"
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
        permissionIcon.image = NSImage(
            systemSymbolName: trusted ? "checkmark.shield.fill" : "hand.raised.fill",
            accessibilityDescription: nil
        )
        permissionIcon.contentTintColor = trusted ? .systemGreen : .systemOrange
        permissionTitle.stringValue = trusted ? "Fast switching" : "Accessibility access needed"
        permissionDetail.stringValue = trusted
            ? "Fast Space switching is available while the app is running."
            : "Allow access once so Space Swipe Lab can respond to your gesture."
        permissionButton.isHidden = trusted
        overrideSwitch.isEnabled = trusted

        if !trusted, engine.isOverrideEnabled {
            engine.stopOverride()
            AppPreferences.overrideEnabled = false
            overrideSwitch.state = .off
            AppPreferences.notifyChanged()
        } else if trusted {
            overrideSwitch.state = engine.isOverrideEnabled ? .on : .off
        }
    }

    private func updateSpeedCaption() {
        let index = speedControl.selectedSegment
        guard speedOptions.indices.contains(index) else {
            return
        }
        speedCaption.stringValue = speedOptions[index].caption
    }

    @objc private func requestPermission() {
        if SpaceSwipeEngine.requestAccessibilityPermission() {
            eventStatus.stringValue = "Accessibility access is ready"
        } else {
            eventStatus.stringValue = "Approve access in System Settings, then return here"
        }
        refreshPermissionStatus()
    }

    @objc private func openAccessibilitySettings() {
        openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    @objc private func openTrackpadSettings() {
        openSystemSettings("x-apple.systempreferences:com.apple.Trackpad-Settings.extension")
    }

    private func openSystemSettings(_ path: String) {
        guard let url = URL(string: path) else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    @objc private func speedChanged() {
        let index = speedControl.selectedSegment
        guard speedOptions.indices.contains(index) else {
            return
        }
        engine.velocity = speedOptions[index].value
        AppPreferences.velocity = engine.velocity
        AppPreferences.notifyChanged()
        updateSpeedCaption()
        let label = speedControl.label(forSegment: index) ?? "selected speed"
        eventStatus.stringValue = "Transition set to \(label)"
    }

    @objc private func switchPrevious() {
        performDirectSwitch(.previous)
    }

    @objc private func switchNext() {
        performDirectSwitch(.next)
    }

    private func performDirectSwitch(_ direction: SpaceDirection) {
        do {
            _ = try engine.postSpaceSwipe(direction)
        } catch {
            show(error: error)
        }
    }

    @objc private func overrideChanged() {
        if overrideSwitch.state == .on {
            do {
                try engine.startOverride()
                AppPreferences.overrideEnabled = true
                eventStatus.stringValue = "Fast swipe is active"
            } catch {
                overrideSwitch.state = .off
                AppPreferences.overrideEnabled = false
                show(error: error)
            }
        } else {
            engine.stopOverride()
            AppPreferences.overrideEnabled = false
            eventStatus.stringValue = "Native macOS swiping restored"
        }
        AppPreferences.notifyChanged()
    }

    @objc private func showOptionsMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false

        let menuBarItem = NSMenuItem(
            title: "Show Menu Bar Icon",
            action: #selector(toggleMenuBarIcon),
            keyEquivalent: ""
        )
        menuBarItem.target = self
        menuBarItem.state = AppPreferences.showMenuBarIcon ? .on : .off
        menu.addItem(menuBarItem)

        let loginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(loginItem)
        menu.addItem(.separator())

        let accessibilityItem = NSMenuItem(
            title: "Accessibility Settings…",
            action: #selector(openAccessibilitySettings),
            keyEquivalent: ""
        )
        accessibilityItem.target = self
        menu.addItem(accessibilityItem)

        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: optionsButton.bounds.height + 4), in: optionsButton)
    }

    @objc private func toggleMenuBarIcon() {
        AppPreferences.showMenuBarIcon.toggle()
        AppPreferences.notifyChanged()
        eventStatus.stringValue = AppPreferences.showMenuBarIcon
            ? "Menu bar icon is visible"
            : "Menu bar icon hidden — reopen the app from Applications"
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
                eventStatus.stringValue = "Launch at login disabled"
            } else {
                try SMAppService.mainApp.register()
                eventStatus.stringValue = "Space Swipe Lab will open when you sign in"
            }
        } catch {
            show(error: error)
        }
    }

    private func show(error: Error) {
        eventStatus.stringValue = error.localizedDescription
        NSAlert(error: error).runModal()
    }
}
