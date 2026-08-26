import Darwin
import Foundation

struct SpaceLayoutSnapshot: Equatable {
    let currentIndex: Int
    let spaceCount: Int

    func canMove(_ direction: SpaceDirection) -> Bool {
        guard spaceCount > 0, currentIndex >= 0, currentIndex < spaceCount else {
            return false
        }

        switch direction {
        case .previous:
            return currentIndex > 0
        case .next:
            return currentIndex + 1 < spaceCount
        }
    }
}

/// Reads the current Mission Control Space order from SkyLight. Apple does not expose a public
/// API for this information, so failure is treated as "unknown" and the existing swipe override
/// remains available rather than disabling the app.
final class SpaceTopology {
    private typealias MainConnectionFunction = @convention(c) () -> Int32
    private typealias ActiveSpaceFunction = @convention(c) (Int32) -> UInt64
    private typealias ManagedSpacesFunction = @convention(c) (
        Int32,
        CFString?
    ) -> Unmanaged<CFArray>?

    private let mainConnection: MainConnectionFunction?
    private let activeSpace: ActiveSpaceFunction?
    private let copyManagedSpaces: ManagedSpacesFunction?

    init() {
        let handle = dlopen(
            "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight",
            RTLD_LAZY | RTLD_LOCAL
        )

        mainConnection = Self.loadSymbol(
            names: ["SLSMainConnectionID", "CGSMainConnectionID"],
            from: handle,
            as: MainConnectionFunction.self
        )
        activeSpace = Self.loadSymbol(
            names: ["SLSGetActiveSpace", "CGSGetActiveSpace"],
            from: handle,
            as: ActiveSpaceFunction.self
        )
        copyManagedSpaces = Self.loadSymbol(
            names: ["SLSCopyManagedDisplaySpaces", "CGSCopyManagedDisplaySpaces"],
            from: handle,
            as: ManagedSpacesFunction.self
        )
    }

    func currentSnapshot() -> SpaceLayoutSnapshot? {
        guard
            let mainConnection,
            let activeSpace,
            let copyManagedSpaces
        else {
            return nil
        }

        let connection = mainConnection()
        guard connection != 0 else {
            return nil
        }

        let activeSpaceID = activeSpace(connection)
        guard
            activeSpaceID != 0,
            let managedSpaces = copyManagedSpaces(connection, nil)?.takeRetainedValue()
        else {
            return nil
        }

        let displays = (managedSpaces as NSArray).compactMap { $0 as? [String: Any] }
        guard !displays.isEmpty else {
            return nil
        }

        let targetDisplay = displays.first(where: {
            Self.spaceID(from: $0["Current Space"]) == activeSpaceID
        }) ?? displays[0]

        return Self.snapshot(from: targetDisplay, activeSpaceID: activeSpaceID)
    }

    static func snapshot(
        from display: [String: Any],
        activeSpaceID: UInt64
    ) -> SpaceLayoutSnapshot? {
        guard let rawSpaces = display["Spaces"] as? [Any] else {
            return nil
        }

        let identifiers = rawSpaces.compactMap { spaceID(from: $0) }
        guard
            !identifiers.isEmpty,
            let currentIndex = identifiers.firstIndex(of: activeSpaceID)
        else {
            return nil
        }

        return SpaceLayoutSnapshot(
            currentIndex: currentIndex,
            spaceCount: identifiers.count
        )
    }

    private static func spaceID(from value: Any?) -> UInt64? {
        guard let dictionary = value as? [String: Any] else {
            return nil
        }
        if let number = dictionary["id64"] as? NSNumber {
            return number.uint64Value
        }
        if let number = dictionary["ManagedSpaceID"] as? NSNumber {
            return number.uint64Value
        }
        return nil
    }

    private static func loadSymbol<T>(
        names: [String],
        from handle: UnsafeMutableRawPointer?,
        as type: T.Type
    ) -> T? {
        guard let handle else {
            return nil
        }

        for name in names {
            if let symbol = dlsym(handle, name) {
                return unsafeBitCast(symbol, to: type)
            }
        }
        return nil
    }
}
