import Foundation

enum TransitionSpeed: Int, CaseIterable, Equatable {
    case normal
    case fast
    case faster
    case instant

    var title: String {
        switch self {
        case .normal: "Normal"
        case .fast: "Fast"
        case .faster: "Faster"
        case .instant: "Instant"
        }
    }

    var caption: String {
        switch self {
        case .normal: "macOS-like motion"
        case .fast: "smooth, reduced motion"
        case .faster: "short, responsive motion"
        case .instant: "near-instant switching"
        }
    }

    var velocity: Double {
        switch self {
        case .normal: 40
        case .fast: 60
        case .faster: 80
        case .instant: 2_000
        }
    }

    static func nearest(to velocity: Double) -> TransitionSpeed {
        allCases.min(by: {
            abs($0.velocity - velocity) < abs($1.velocity - velocity)
        }) ?? .instant
    }
}
