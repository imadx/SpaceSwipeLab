import ApplicationServices
import CoreGraphics
import Foundation

enum SpaceDirection: String, Equatable {
    case previous
    case next

    var sign: Double {
        self == .next ? 1.0 : -1.0
    }

    var displayName: String {
        self == .next ? "Next Space" : "Previous Space"
    }
}

struct DockSwipeStateMachine {
    private(set) var isTracking = false
    private(set) var hasFired = false

    mutating func consume(
        phase: Int64,
        progress: Double,
        velocityX: Double
    ) -> SpaceDirection? {
        switch phase {
        case 1: // began
            isTracking = true
            hasFired = false
            return nil

        case 2: // changed
            guard isTracking, !hasFired, progress != 0 else {
                return nil
            }
            hasFired = true
            return progress > 0 ? .next : .previous

        case 4: // ended
            defer { reset() }
            guard isTracking, !hasFired, velocityX != 0 else {
                return nil
            }
            hasFired = true
            return velocityX > 0 ? .next : .previous

        case 8: // cancelled
            reset()
            return nil

        default:
            return nil
        }
    }

    mutating func reset() {
        isTracking = false
        hasFired = false
    }
}

enum SpaceSwipeEngineError: LocalizedError {
    case accessibilityPermissionRequired
    case eventTapCreationFailed

    var errorDescription: String? {
        switch self {
        case .accessibilityPermissionRequired:
            return "Accessibility permission is required before Space switching can be controlled."
        case .eventTapCreationFailed:
            return "macOS refused to create the gesture event tap. Re-enable Accessibility permission and relaunch the app."
        }
    }
}

final class SpaceSwipeEngine {
    var velocity: Double = 2_000
    var onSwitch: ((SpaceDirection) -> Void)?
    var onBoundary: ((SpaceDirection) -> Void)?

    enum CompanionEventHandling: Equatable {
        case passThrough
        case bufferAndSuppress
        case suppress
    }

    enum GestureRoutingState {
        case idle
        case pendingDirection
        case replacement
        case nativeBoundary

        var companionEventHandling: CompanionEventHandling {
            switch self {
            case .idle, .nativeBoundary:
                return .passThrough
            case .pendingDirection:
                return .bufferAndSuppress
            case .replacement:
                return .suppress
            }
        }
    }

    private static let replayMarker: Int64 = 0x5353_504C
    private let spaceTopology: SpaceTopology
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var stateMachine = DockSwipeStateMachine()
    private var routingState = GestureRoutingState.idle
    private var bufferedNativeEvents: [CGEvent] = []

    init(spaceTopology: SpaceTopology = SpaceTopology()) {
        self.spaceTopology = spaceTopology
    }

    var isOverrideEnabled: Bool {
        eventTap != nil
    }

    static var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    @discardableResult
    static func requestAccessibilityPermission() -> Bool {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        return AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
    }

    @discardableResult
    func postSpaceSwipe(_ direction: SpaceDirection) throws -> Bool {
        guard Self.isAccessibilityTrusted else {
            throw SpaceSwipeEngineError.accessibilityPermissionRequired
        }

        if let snapshot = spaceTopology.currentSnapshot(), !snapshot.canMove(direction) {
            onBoundary?(direction)
            return false
        }

        postReplacementSpaceSwipe(direction)
        return true
    }

    private func postReplacementSpaceSwipe(_ direction: SpaceDirection) {
        
        let signedVelocity = direction.sign * velocity
        let progress = direction.sign * Double(Float.leastNonzeroMagnitude)

        // Dock expects a complete began -> changed -> ended gesture sequence.
        for phase: Int64 in [1, 2, 4] {
            guard let event = CGEvent(source: nil) else {
                continue
            }

            event.setIntegerValueField(Self.field(55), value: 30)   // Dock control event
            event.setIntegerValueField(Self.field(110), value: 23) // Dock swipe HID event
            event.setIntegerValueField(Self.field(123), value: 1)  // Horizontal motion
            event.setDoubleValueField(Self.field(124), value: progress)
            event.setDoubleValueField(Self.field(129), value: signedVelocity)
            event.setDoubleValueField(Self.field(130), value: signedVelocity)
            event.setIntegerValueField(Self.field(132), value: phase)
            event.post(tap: .cgSessionEventTap)
        }

        onSwitch?(direction)
    }

    func startOverride() throws {
        guard Self.isAccessibilityTrusted else {
            throw SpaceSwipeEngineError.accessibilityPermissionRequired
        }
        guard eventTap == nil else {
            return
        }

        let mask =
            (CGEventMask(1) << 29) | // Companion gesture event
            (CGEventMask(1) << 30)   // Dock control event

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: Self.eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            throw SpaceSwipeEngineError.eventTapCreationFailed
        }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            CFMachPortInvalidate(tap)
            throw SpaceSwipeEngineError.eventTapCreationFailed
        }

        eventTap = tap
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stopOverride() {
        stateMachine.reset()
        resetGestureRouting()

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }

        runLoopSource = nil
        eventTap = nil
    }

    deinit {
        stopOverride()
    }

    private func handleTapEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        if event.getIntegerValueField(.eventSourceUserData) == Self.replayMarker {
            return Unmanaged.passUnretained(event)
        }

        let internalType = event.getIntegerValueField(Self.field(55))

        // Real HID gestures use source PID 0. Let our synthetic events pass through so the
        // replacement gesture does not recursively trigger this event tap.
        if internalType == 29 || internalType == 30 {
            let sourcePID = event.getIntegerValueField(.eventSourceUnixProcessID)
            if sourcePID != 0 {
                return Unmanaged.passUnretained(event)
            }
        }

        if internalType == 30 {
            let hidType = event.getIntegerValueField(Self.field(110))
            let motion = event.getIntegerValueField(Self.field(123))
            guard hidType == 23, motion == 1 else {
                return Unmanaged.passUnretained(event)
            }

            let phase = event.getIntegerValueField(Self.field(132))
            let progress = event.getDoubleValueField(Self.field(124))
            let velocityX = event.getDoubleValueField(Self.field(129))

            if phase == 1 {
                _ = stateMachine.consume(
                    phase: phase,
                    progress: progress,
                    velocityX: velocityX
                )
                let isAlreadyBuffering: Bool
                if case .pendingDirection = routingState {
                    isAlreadyBuffering = true
                } else {
                    isAlreadyBuffering = false
                }
                // A companion event can arrive just before Dock's control event.
                if !isAlreadyBuffering {
                    bufferedNativeEvents.removeAll(keepingCapacity: true)
                }
                routingState = .pendingDirection
                bufferForNativeReplay(event)
                return nil
            }

            let direction = stateMachine.consume(
                phase: phase,
                progress: progress,
                velocityX: velocityX
            )

            if routingState == .pendingDirection {
                if let direction {
                    chooseRouting(for: direction)
                } else if phase == 2 {
                    bufferForNativeReplay(event)
                }
            }

            let shouldUseNativeGesture = routingState == .nativeBoundary
            if phase == 4 || phase == 8 {
                resetGestureRouting()
            }

            // Valid switches use our replacement gesture. At either boundary, the original
            // gesture sequence is replayed and all remaining events stay native.
            return shouldUseNativeGesture ? Unmanaged.passUnretained(event) : nil
        }

        // Gesture events also carry pinch, smart zoom, and other trackpad input. Do not consume
        // them until Dock has identified an active horizontal Space swipe with a control event.
        // Once identified, hold companion events until the direction is known so they can be
        // restored for first/last-Space feedback.
        if internalType == 29 {
            switch routingState.companionEventHandling {
            case .bufferAndSuppress:
                bufferForNativeReplay(event)
                return nil
            case .suppress:
                return nil
            case .passThrough:
                return Unmanaged.passUnretained(event)
            }
        }

        return Unmanaged.passUnretained(event)
    }

    private func chooseRouting(for direction: SpaceDirection) {
        if let snapshot = spaceTopology.currentSnapshot(), !snapshot.canMove(direction) {
            routingState = .nativeBoundary
            replayBufferedNativeEvents()
            onBoundary?(direction)
            return
        }

        routingState = .replacement
        bufferedNativeEvents.removeAll(keepingCapacity: true)
        postReplacementSpaceSwipe(direction)
    }

    private func bufferForNativeReplay(_ event: CGEvent) {
        guard bufferedNativeEvents.count < 12, let copiedEvent = event.copy() else {
            return
        }
        bufferedNativeEvents.append(copiedEvent)
    }

    private func replayBufferedNativeEvents() {
        for event in bufferedNativeEvents {
            guard let replay = event.copy() else {
                continue
            }
            replay.setIntegerValueField(.eventSourceUserData, value: Self.replayMarker)
            replay.post(tap: .cgSessionEventTap)
        }
        bufferedNativeEvents.removeAll(keepingCapacity: true)
    }

    private func resetGestureRouting() {
        routingState = .idle
        bufferedNativeEvents.removeAll(keepingCapacity: true)
    }

    private static let eventTapCallback: CGEventTapCallBack = {
        _, type, event, userInfo in
        guard let userInfo else {
            return Unmanaged.passUnretained(event)
        }
        let engine = Unmanaged<SpaceSwipeEngine>
            .fromOpaque(userInfo)
            .takeUnretainedValue()
        return engine.handleTapEvent(type: type, event: event)
    }

    private static func field(_ rawValue: UInt32) -> CGEventField {
        guard let field = CGEventField(rawValue: rawValue) else {
            preconditionFailure("Unsupported CGEvent field: \(rawValue)")
        }
        return field
    }
}
