//
//  ComposeTests.swift
//
//  Created by Daniel Tartaglia on 20 Jul 2022.
//  Copyright © 2022 Daniel Tartaglia. MIT License.
//

import RxCache
import RxSwift
import RxTest
import XCTest

final class ComposeTests: XCTestCase {
	func testAssetInFirst() {
		let scheduler = TestScheduler(initialClock: 0)
		let cacheAGetParams = scheduler.createObserver(String.self)
		let getAMock = scheduler.mock(args: cacheAGetParams, timelineSelector: { _ in "-A|" })
		let cacheA = Cache<String, String>(
			get: getAMock,
			set: { _, _ in XCTFail("Should not call this."); return .just(()) }
		)
		let cacheB = Cache<String, String>(
			get: { _ in XCTFail("Should not call this."); return .just("") },
			set: { _, _ in XCTFail("Should not call this."); return .just(()) }
		)

		let sut = compose(cacheA, cacheB)

		let result = scheduler.start {
			sut.get(key: "key")
		}

		XCTAssertEqual(cacheAGetParams.events, [.next(100, "key")])
		XCTAssertEqual(result.events, [.next(201, "A"), .completed(201)])
	}

	func testAssetInSecond() {
		let scheduler = TestScheduler(initialClock: 0)
		let cacheAGetParams = scheduler.createObserver(String.self)
		let cacheASetParams = scheduler.createObserver(Pair<String, String>.self)
		let getAMock = scheduler.mock(args: cacheAGetParams, timelineSelector: { _ in "-#" })
		let setAMock = scheduler.mock(args: cacheASetParams, values: ["A": ()], timelineSelector: { _ in "-A|" })
		let cacheA = Cache<String, String>(
			get: getAMock,
			set: { setAMock(Pair(left: $0, right: $1)) }
		)
		let cacheBGetParams = scheduler.createObserver(String.self)
		let getBMock = scheduler.mock(args: cacheBGetParams, timelineSelector: { _ in "-B|" })
		let cacheB = Cache<String, String>(
			get: getBMock,
			set: { _, _ in XCTFail("Should not call this."); return .just(()) }
		)

		let sut = compose(cacheA, cacheB)

		let result = scheduler.start {
			sut.get(key: "key")
		}

		XCTAssertEqual(cacheAGetParams.events, [.next(100, "key")])
		XCTAssertEqual(cacheASetParams.events, [.next(202, Pair(left: "key", right: "B"))])
		XCTAssertEqual(cacheBGetParams.events, [.next(201, "key")])
		XCTAssertEqual(result.events, [.next(202, "B"), .completed(203)])
	}

	func testAssetMissing() {
		let scheduler = TestScheduler(initialClock: 0)
		let cacheAGetParams = scheduler.createObserver(String.self)
		let getAMock = scheduler.mock(args: cacheAGetParams, timelineSelector: { _ in "-#" })
		let cacheA = Cache<String, String>(
			get: getAMock,
			set: { _, _ in XCTFail("Should not call this."); return .just(()) }
		)

		let cacheBGetParams = scheduler.createObserver(String.self)
		let getBMock = scheduler.mock(args: cacheBGetParams, timelineSelector: { _ in "-#" })
		let cacheB = Cache<String, String>(
			get: getBMock,
			set: { _, _ in XCTFail("Should not call this."); return .just(()) }
		)

		let sut = compose(cacheA, cacheB)

		let result = scheduler.start {
			sut.get(key: "key")
		}

		let expectedError = NSError(domain: "Test Domain", code: -1)
		XCTAssertEqual(cacheAGetParams.events, [.next(100, "key")])
		XCTAssertEqual(cacheBGetParams.events, [.next(201, "key")])
		XCTAssertEqual(result.events, [.error(202, CacheError.multiple(expectedError, expectedError))])
	}

	func testSetFailure() {
		let scheduler = TestScheduler(initialClock: 0)
		let cacheAGetParams = scheduler.createObserver(String.self)
		let getAMock = scheduler.mock(args: cacheAGetParams, timelineSelector: { _ in "-#" })
		let cacheASetParams = scheduler.createObserver(Pair<String, String>.self)
		let setAMock = scheduler.mock(args: cacheASetParams, values: ["X": ()], timelineSelector: { _ in "-#" })
		let cacheA = Cache<String, String>(
			get: getAMock,
			set: { setAMock(Pair(left: $0, right: $1)) }
		)
		let cacheBGetParams = scheduler.createObserver(String.self)
		let getBMock = scheduler.mock(args: cacheBGetParams, timelineSelector: { _ in "-B" })
		let cacheB = Cache<String, String>(
			get: getBMock,
			set: { _, _ in XCTFail("Should not call this."); return .just(()) }
		)

		let sut = compose(cacheA, cacheB)

		let result = scheduler.start {
			sut.get(key: "key")
		}

		let expectedError = NSError(domain: "Test Domain", code: -1)
		XCTAssertEqual(cacheAGetParams.events, [.next(100, "key")])
		XCTAssertEqual(cacheASetParams.events, [.next(202, Pair(left: "key", right: "B"))])
		XCTAssertEqual(cacheBGetParams.events, [.next(201, "key")])
		XCTAssertEqual(result.events, [.next(202, "B"), .error(203, CacheError.multiple(expectedError, expectedError))])
	}

	func testSetBoth() {
		let scheduler = TestScheduler(initialClock: 0)
		let cacheASetParams = scheduler.createObserver(Pair<String, String>.self)
		let setAMock = scheduler.mock(args: cacheASetParams, values: ["A": ()], timelineSelector: { _ in "-A|" })
		let cacheA = Cache<String, String>(
			get: { _ in XCTFail("Should not call this."); return .just("") },
			set: { setAMock(Pair(left: $0, right: $1)) }
		)
		let cacheBSetParams = scheduler.createObserver(Pair<String, String>.self)
		let setBMock = scheduler.mock(args: cacheBSetParams, values: ["B": ()], timelineSelector: { _ in "-B|" })
		let cacheB = Cache<String, String>(
			get: { _ in XCTFail("Should not call this."); return .just("") },
			set: { setBMock(Pair(left: $0, right: $1)) }
		)

		let sut = compose(cacheA, cacheB)

		let result = scheduler.start {
			sut.set(key: "key", value: "value")
				.map { _ in true }
		}

		XCTAssertEqual(cacheASetParams.events, [.next(100, Pair(left: "key", right: "value"))])
		XCTAssertEqual(cacheBSetParams.events, [.next(100, Pair(left: "key", right: "value"))])
		XCTAssertEqual(result.events, [.next(201, true), .completed(201)])
	}
}
