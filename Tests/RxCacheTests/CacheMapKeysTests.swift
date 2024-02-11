//
//  CacheMapKeysTests.swift
//
//  Created by Daniel Tartaglia on 20 Jul 2022.
//  Copyright © 2024 Daniel Tartaglia. MIT License.
//

import RxCache
import RxSwift
import RxTest
import XCTest

final class CacheMapKeysTests: XCTestCase {
	func testHappyPath() {
		let scheduler = TestScheduler(initialClock: 0)
		let getParam = scheduler.createObserver(String.self)
		let setParam = scheduler.createObserver(Pair<String, Int>.self)
		let getMock = scheduler.mock(args: getParam, values: ["A": 12], timelineSelector: { _ in "-A|" })
		let setMock = scheduler.mock(args: setParam, values: ["A": ()], timelineSelector: { _ in "-A|" })
		let cache = Cache<String, Int>(
			get: getMock,
			set: { key, value in setMock(Pair(left: key, right: value)) }
		)
		let mappedCache: Cache<Int, Int> = cache.mapKeys { "\($0)" }

		let getResult = scheduler.createObserver(Int.self)
		_ = mappedCache.get(key: 13)
			.subscribe(getResult)

		let setResult = scheduler.createObserver(Bool.self)
		_ = mappedCache.set(key: 11, value: 17)
			.map { true }
			.subscribe(setResult)

		scheduler.start()

		XCTAssertEqual(getParam.events, [.next(0, "13")])
		XCTAssertEqual(setParam.events, [.next(0, Pair(left: "11", right: 17))])
		XCTAssertEqual(getResult.events, [.next(1, 12), .completed(1)])
		XCTAssertEqual(setResult.events, [.next(1, true), .completed(1)])
	}

	func testMappingFails() {
		let scheduler = TestScheduler(initialClock: 0)
		let cache = Cache<String, Int>(
			get: { _ in XCTFail("Should not call this."); return .just(3) },
			set: { _, _ in XCTFail("Should not call this."); return .just(()) }
		)
		let mappedCache: Cache<Int, Int> = cache.mapKeys { _ in throw MapTestError.failInv }

		let getResult = scheduler.createObserver(Int.self)
		_ = mappedCache.get(key: 7)
			.subscribe(getResult)

		let setResult = scheduler.createObserver(Bool.self)
		_ = mappedCache.set(key: 19, value: 17)
			.map { true }
			.subscribe(setResult)

		scheduler.start()

		XCTAssertEqual(getResult.events, [.error(0, MapTestError.failInv)])
		XCTAssertEqual(setResult.events, [.error(0, MapTestError.failInv)])
	}
}
