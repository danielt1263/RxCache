@testable import RxCache
import RxSwift
import RxTest
import XCTest

final class ComposeTests: XCTestCase {
	func testAssetInFirst() {
		let scheduler = TestScheduler(initialClock: 0)
		let cacheA = Cache<String, String>(
			get: { _ in .just("hello") },
			set: { _, _ in XCTFail(); return .just(()) }
		)
		let cacheB = Cache<String, String>(
			get: { _ in XCTFail(); return .just("") },
			set: { _, _ in XCTFail(); return .just(()) }
		)

		let sut = compose(cacheA, cacheB)

		let result = scheduler.start {
			sut.get(key: "key")
		}

		XCTAssertEqual(result.events, [.next(200, "hello"), .completed(200)])
	}

	func testAssetInSecond() {
		let scheduler = TestScheduler(initialClock: 0)
		var setACalled = false
		let cacheA = Cache<String, String>(
			get: { _ in .error(TestError.getA) },
			set: { _, _ in setACalled = true; return .just(()) }
		)
		let cacheB = Cache<String, String>(
			get: { _ in .just("goodbye") },
			set: { _, _ in XCTFail(); return .just(()) }
		)

		let sut = compose(cacheA, cacheB)

		let result = scheduler.start {
			sut.get(key: "key")
		}

		XCTAssertTrue(setACalled)
		XCTAssertEqual(result.events, [.next(200, "goodbye"), .completed(200)])
	}

	func testAssetMissing() {
		let scheduler = TestScheduler(initialClock: 0)
		let cacheA = Cache<String, String>(
			get: { _ in .error(TestError.getA) },
			set: { _, _ in XCTFail(); return .just(()) }
		)
		let cacheB = Cache<String, String>(
			get: { _ in .error(TestError.getB) },
			set: { _, _ in XCTFail(); return .just(()) }
		)

		let sut = compose(cacheA, cacheB)

		let result = scheduler.start {
			sut.get(key: "key")
		}

		XCTAssertEqual(result.events, [.error(200, CacheError.multiple(TestError.getA, TestError.getB))])
	}

	func testSetFailure() {
		let scheduler = TestScheduler(initialClock: 0)
		let cacheA = Cache<String, String>(
			get: { _ in .error(TestError.getA) },
			set: { _, _ in .error(TestError.setA) }
		)
		let cacheB = Cache<String, String>(
			get: { _ in .just("goodbye") },
			set: { _, _ in XCTFail(); return .just(()) }
		)

		let sut = compose(cacheA, cacheB)

		let result = scheduler.start {
			sut.get(key: "key")
		}

		XCTAssertEqual(result.events, [.next(200, "goodbye"), .error(200, CacheError.multiple(TestError.getA, TestError.setA))])
	}

	func testSetBoth() {
		let scheduler = TestScheduler(initialClock: 0)
		var setACalled = false
		var setBCalled = false
		let cacheA = Cache<String, String>(
			get: { _ in XCTFail(); return .just("") },
			set: { _, _ in setACalled = true; return .just(()) }
		)
		let cacheB = Cache<String, String>(
			get: { _ in XCTFail(); return .just("") },
			set: { _, _ in setBCalled = true; return .just(()) }
		)

		let sut = compose(cacheA, cacheB)

		let result = scheduler.start {
			sut.set(key: "key", value: "value")
				.map { _ in true }
		}

		XCTAssertTrue(setACalled)
		XCTAssertTrue(setBCalled)
		XCTAssertEqual(result.events, [.next(200, true), .completed(200)])
	}
}

enum TestError: Error {
	case getA
	case getB
	case setA
}
