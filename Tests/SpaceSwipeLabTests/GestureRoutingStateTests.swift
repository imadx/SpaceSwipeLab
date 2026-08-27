import XCTest
@testable import SpaceSwipeLab

final class GestureRoutingStateTests: XCTestCase {
    func testIdleCompanionGesturesPassThrough() {
        XCTAssertEqual(
            SpaceSwipeEngine.GestureRoutingState.idle.companionEventHandling,
            .passThrough
        )
    }

    func testPendingSpaceSwipeBuffersCompanionGestures() {
        XCTAssertEqual(
            SpaceSwipeEngine.GestureRoutingState.pendingDirection.companionEventHandling,
            .bufferAndSuppress
        )
    }

    func testReplacementSpaceSwipeSuppressesCompanionGestures() {
        XCTAssertEqual(
            SpaceSwipeEngine.GestureRoutingState.replacement.companionEventHandling,
            .suppress
        )
    }

    func testNativeBoundaryCompanionGesturesPassThrough() {
        XCTAssertEqual(
            SpaceSwipeEngine.GestureRoutingState.nativeBoundary.companionEventHandling,
            .passThrough
        )
    }
}
