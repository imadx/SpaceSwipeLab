import XCTest
@testable import SpaceSwipeLab

final class TransitionSpeedTests: XCTestCase {
    func testFourSpeedsAreOrderedFromNormalToInstant() {
        XCTAssertEqual(
            TransitionSpeed.allCases.map(\.title),
            ["Normal", "Fast", "Faster", "Instant"]
        )
        XCTAssertEqual(
            TransitionSpeed.allCases.map(\.velocity),
            [40, 60, 80, 2_000]
        )
    }

    func testSavedVelocitiesSnapToNearestSpeed() {
        XCTAssertEqual(TransitionSpeed.nearest(to: 40), .normal)
        XCTAssertEqual(TransitionSpeed.nearest(to: 58), .fast)
        XCTAssertEqual(TransitionSpeed.nearest(to: 80), .faster)
        XCTAssertEqual(TransitionSpeed.nearest(to: 2_000), .instant)
    }
}
