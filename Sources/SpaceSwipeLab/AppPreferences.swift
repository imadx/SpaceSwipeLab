import Foundation

enum AppPreferences {
    private enum Key {
        static let velocity = "transitionVelocity"
        static let overrideEnabled = "swipeOverrideEnabled"
        static let showMenuBarIcon = "showMenuBarIcon"
    }

    static var velocity: Double {
        get {
            let saved = UserDefaults.standard.double(forKey: Key.velocity)
            return saved > 0 ? saved : 2_000
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.velocity)
        }
    }

    static var overrideEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Key.overrideEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: Key.overrideEnabled) }
    }

    static var showMenuBarIcon: Bool {
        get {
            guard UserDefaults.standard.object(forKey: Key.showMenuBarIcon) != nil else {
                return true
            }
            return UserDefaults.standard.bool(forKey: Key.showMenuBarIcon)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.showMenuBarIcon)
        }
    }

    static let didChangeNotification = Notification.Name("SpaceSwipeLabPreferencesDidChange")

    static func notifyChanged() {
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }
}
