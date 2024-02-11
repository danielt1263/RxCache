//
//  RamCacheTests.swift
//
//  Created by Daniel Tartaglia on 20 Jul 2022.
//  Copyright © 2024 Daniel Tartaglia. MIT License.
//

import RxCache
import RxSwift
import RxTest
import XCTest

final class RamCacheTests: XCTestCase {
	func testEmitsErrorWhenDataMissing() {
		let scheduler = TestScheduler(initialClock: 0)
		let sut = RamCache<String, String>()

		let result = scheduler.start {
			sut.get(key: "hello")
		}

		XCTAssertEqual(result.events, [.error(200, CacheError.valueNotInCache)])
	}

	func testEmitsStoredValue() {
		let scheduler = TestScheduler(initialClock: 0)
		let disposeBag = DisposeBag()
		let sut = RamCache<String, String>()

		sut.set(key: "hello", value: "world")
			.subscribe()
			.disposed(by: disposeBag)

		let result = scheduler.start {
			sut.get(key: "hello")
		}

		XCTAssertEqual(result.events, [.next(200, "world"), .completed(200)])
	}
}
