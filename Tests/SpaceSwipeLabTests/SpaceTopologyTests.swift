import XCTest
@testable import SpaceSwipeLab

final class SpaceTopologyTests: XCTestCase {
    func testLiveTopologyReadsAValidCurrentSpaceWhenSkyLightIsAvailable() throws {
        guard let snapshot = SpaceTopology().currentSnapshot() else {
            throw XCTSkip("SkyLight Space information is unavailable in this test session")
        }

        XCTAssertGreaterThan(snapshot.spaceCount, 0)
        XCTAssertGreaterThanOrEqual(snapshot.currentIndex, 0)
        XCTAssertLessThan(snapshot.currentIndex, snapshot.spaceCount)
    }

    func testFirstSpaceKeepsPreviousNativeButAllowsNext() {
        let snapshot = SpaceLayoutSnapshot(currentIndex: 0, spaceCount: 3)

        XCTAssertFalse(snapshot.canMove(.previous))
        XCTAssertTrue(snapshot.canMove(.next))
    }

    func testMiddleSpaceAllowsBothDirections() {
        let snapshot = SpaceLayoutSnapshot(currentIndex: 1, spaceCount: 3)

        XCTAssertTrue(snapshot.canMove(.previous))
        XCTAssertTrue(snapshot.canMove(.next))
    }

    func testLastSpaceKeepsNextNativeButAllowsPrevious() {
        let snapshot = SpaceLayoutSnapshot(currentIndex: 2, spaceCount: 3)

        XCTAssertTrue(snapshot.canMove(.previous))
        XCTAssertFalse(snapshot.canMove(.next))
    }

    func testManagedSpaceDictionaryPreservesMissionControlOrder() {
        let display: [String: Any] = [
            "Spaces": [
                ["id64": NSNumber(value: 11)],
                ["id64": NSNumber(value: 22)],
                ["id64": NSNumber(value: 33)]
            ]
        ]

        XCTAssertEqual(
            SpaceTopology.snapshot(from: display, activeSpaceID: 22),
            SpaceLayoutSnapshot(currentIndex: 1, spaceCount: 3)
        )
    }
}
