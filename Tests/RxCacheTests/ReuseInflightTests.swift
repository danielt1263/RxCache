//
//  ReuseInflightTests.swift
//
//  Created by Daniel Tartaglia on 20 Jul 2022.
//  Copyright © 2022 Daniel Tartaglia. MIT License.
//

import RxCache
import RxSwift
import RxTest
import XCTest

final class ReuseInflightTests: XCTestCase {
	var scheduler: TestScheduler!
	var disposeBag: DisposeBag!
	var result1: TestableObserver<String>!
	var result2: TestableObserver<String>!
	var getParam: TestableObserver<String>!
	var setParam: TestableObserver<Pair<String, String>>!
	var fakeCache: Cache<String, String>!
	var sut: Cache<String, String>!

	override func setUp() {
		scheduler = TestScheduler(initialClock: 0)
		disposeBag = DisposeBag()
		result1 = scheduler.createObserver(String.self)
		result2 = scheduler.createObserver(String.self)
		getParam = scheduler.createObserver(String.self)
		setParam = scheduler.createObserver(Pair<String, String>.self)
		let getMock = scheduler.mock(
			args: getParam,
			timelineSelector: { param in param == "hello" ? "---A-|" : "---B-|" }
		)
		let setMock = scheduler.mock(args: setParam, values: ["A": ()], timelineSelector: { _ in "---A|"})
		fakeCache = Cache<String, String>(
			get: getMock,
			set: { setMock(Pair(left: $0, right: $1)) }
		)

		sut = fakeCache.reuseInflight()
	}

	func testPoolsCalls() {
		sut.get(key: "hello")
			.subscribe(result1)
			.disposed(by: disposeBag)

		scheduler.scheduleAt(2) {
			self.sut.get(key: "hello")
				.subscribe(self.result2)
				.disposed(by: self.disposeBag)
		}
		scheduler.start()

		XCTAssertEqual(getParam.events, [.next(0, "hello")])
		XCTAssertEqual(result1.events, [.next(3, "A"), .completed(4)])
		XCTAssertEqual(result2.events, [.next(3, "A"), .completed(4)])
	}

	func testRaceConditionReturnsValue() {
		sut.get(key: "hello")
			.subscribe(result1)
			.disposed(by: disposeBag)

		scheduler.scheduleAt(3) {
			self.sut.get(key: "hello")
				.subscribe(self.result2)
				.disposed(by: self.disposeBag)
		}
		scheduler.start()

		XCTAssertEqual(getParam.events, [.next(0, "hello")])
		XCTAssertEqual(result1.events, [.next(3, "A"), .completed(4)])
		XCTAssertEqual(result2.events, [.next(3, "A"), .completed(4)])
	}

	func testOnlyPoolsIncompleteCalls() {
		sut.get(key: "hello")
			.subscribe(result1)
			.disposed(by: disposeBag)

		scheduler.scheduleAt(4) {
			self.sut.get(key: "hello")
				.subscribe(self.result2)
				.disposed(by: self.disposeBag)
		}
		scheduler.start()

		XCTAssertEqual(getParam.events, [.next(0, "hello"), .next(4, "hello")])
		XCTAssertEqual(result1.events, [.next(3, "A"), .completed(4)])
		XCTAssertEqual(result2.events, [.next(7, "A"), .completed(8)])
	}

	func testDifferentKeys() {
		sut.get(key: "hello")
			.subscribe(result1)
			.disposed(by: disposeBag)

		sut.get(key: "world")
			.subscribe(result2)
			.disposed(by: disposeBag)

		scheduler.start()

		XCTAssertEqual(getParam.events, [.next(0, "hello"), .next(0, "world")])
		XCTAssertEqual(result1.events, [.next(3, "A"), .completed(4)])
		XCTAssertEqual(result2.events, [.next(3, "B"), .completed(4)])
	}
}
