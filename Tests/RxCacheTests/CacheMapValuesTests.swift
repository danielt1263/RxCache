//
//  CacheMapValuesTests.swift
//
//  Created by Daniel Tartaglia on 20 Jul 2022.
//  Copyright © 2024 Daniel Tartaglia. MIT License.
//

import RxCache
import RxSwift
import RxTest
import XCTest

final class CacheMapValuesTests: XCTestCase {
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
		let mappedCache = cache.mapValues({ "\($0)" }, { text in
			guard let val = Int(text) else { throw MapTestError.fail }
			return val
		})

		let getResult = scheduler.createObserver(String.self)
		_ = mappedCache.get(key: "test")
			.subscribe(getResult)

		let setResult = scheduler.createObserver(Bool.self)
		_ = mappedCache.set(key: "test", value: "17")
			.map { true }
			.subscribe(setResult)

		scheduler.start()

		XCTAssertEqual(getParam.events, [.next(0, "test")])
		XCTAssertEqual(setParam.events, [.next(0, Pair(left: "test", right: 17))])
		XCTAssertEqual(getResult.events, [.next(1, "12"), .completed(1)])
		XCTAssertEqual(setResult.events, [.next(1, true), .completed(1)])
	}

	func testMappingFails() {
		let scheduler = TestScheduler(initialClock: 0)
		let getParam = scheduler.createObserver(String.self)
		let getMock = scheduler.mock(args: getParam, values: ["A": 12], timelineSelector: { _ in "-A|" })
		let cache = Cache<String, Int>(
			get: getMock,
			set: { _, _ in XCTFail("Should not call this."); return .just(()) }
		)
		let mappedCache = cache.mapValues({ _ -> String in throw MapTestError.fail }, { _ in
			throw MapTestError.failInv
		})

		let getResult = scheduler.createObserver(String.self)
		_ = mappedCache.get(key: "test")
			.subscribe(getResult)

		let setResult = scheduler.createObserver(Bool.self)
		_ = mappedCache.set(key: "test", value: "17")
			.map { true }
			.subscribe(setResult)

		scheduler.start()

		XCTAssertEqual(getParam.events, [.next(0, "test")])
		XCTAssertEqual(getResult.events, [.error(1, MapTestError.fail)])
		XCTAssertEqual(setResult.events, [.error(0, MapTestError.failInv)])
	}
}

struct Pair<A, B> {
	let left: A
	let right: B
}

extension Pair: Equatable where A: Equatable, B: Equatable { }

enum MapTestError: Error {
	case fail
	case failInv
}
