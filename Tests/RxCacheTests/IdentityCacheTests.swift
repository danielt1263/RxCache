@testable import RxCache
import RxTest
import XCTest

final class IdentityCacheTests: XCTestCase {
	func testGetEmitsError() {
		let scheduler = TestScheduler(initialClock: 0)
		let sut = IdentityCache<String, String>()
		let result = scheduler.start {
			sut.get(key: "hello")
		}
		XCTAssertEqual(result.events, [.error(200, CacheError.identity)])
	}

	func testSetEmitsSuccess() {
		let scheduler = TestScheduler(initialClock: 0)
		let sut = IdentityCache<String, String>()
		let result = scheduler.start {
			sut.set(key: "hello", value: "")
				.map { _ in true }
		}
		XCTAssertEqual(result.events, [.next(200, true), .completed(200)])
	}
}
