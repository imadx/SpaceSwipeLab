import XCTest
@testable import SpaceSwipeLab

final class DockSwipeStateMachineTests: XCTestCase {
    func testChangedPhaseFiresNextExactlyOnce() {
        var state = DockSwipeStateMachine()

        XCTAssertNil(state.consume(phase: 1, progress: 0, velocityX: 0))
        XCTAssertEqual(state.consume(phase: 2, progress: 0.2, velocityX: 4), .next)
        XCTAssertNil(state.consume(phase: 2, progress: 0.4, velocityX: 8))
        XCTAssertNil(state.consume(phase: 4, progress: 0, velocityX: 8))
        XCTAssertFalse(state.isTracking)
    }

    func testNegativeProgressFiresPrevious() {
        var state = DockSwipeStateMachine()

        XCTAssertNil(state.consume(phase: 1, progress: 0, velocityX: 0))
        XCTAssertEqual(state.consume(phase: 2, progress: -0.2, velocityX: -4), .previous)
    }

    func testEndedPhaseFallsBackToVelocity() {
        var state = DockSwipeStateMachine()

        XCTAssertNil(state.consume(phase: 1, progress: 0, velocityX: 0))
        XCTAssertEqual(state.consume(phase: 4, progress: 0, velocityX: -20), .previous)
        XCTAssertFalse(state.isTracking)
    }

    func testCancellationResetsTracking() {
        var state = DockSwipeStateMachine()

        XCTAssertNil(state.consume(phase: 1, progress: 0, velocityX: 0))
        XCTAssertNil(state.consume(phase: 8, progress: 0, velocityX: 0))
        XCTAssertFalse(state.isTracking)
        XCTAssertNil(state.consume(phase: 2, progress: 0.5, velocityX: 10))
    }
}
