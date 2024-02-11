//
//  IdentityCacheTests.swift
//
//  Created by Daniel Tartaglia on 20 Jul 2022.
//  Copyright © 2024 Daniel Tartaglia. MIT License.
//

import RxCache
import RxTest
import XCTest

final class IdentityCacheTests: XCTestCase {
	func testGetEmitsError() {
		let scheduler = TestScheduler(initialClock: 0)
		let sut = Cache<String, String>()
		let result = scheduler.start {
			sut.get(key: "hello")
		}
		XCTAssertEqual(result.events, [.error(200, CacheError.identity)])
	}

	func testSetEmitsSuccess() {
		let scheduler = TestScheduler(initialClock: 0)
		let sut = Cache<String, String>()
		let result = scheduler.start {
			sut.set(key: "hello", value: "")
				.map { _ in true }
		}
		XCTAssertEqual(result.events, [.next(200, true), .completed(200)])
	}
}
