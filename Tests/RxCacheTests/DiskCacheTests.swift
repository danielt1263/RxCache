//
//  DiskCacheTests.swift
//
//  Created by Daniel Tartaglia on 20 Jul 2022.
//  Copyright © 2022 Daniel Tartaglia. MIT License.
//

import RxCache
import RxSwift
import RxTest
import XCTest

final class DiskCacheTests: XCTestCase {
	func testEmitsErrorWhenMissingData() {
		let scheduler = TestScheduler(initialClock: 0)
		let tempDirectory = findTemporaryDirectory()
		let sut = DiskCache<String>(directory: tempDirectory, scheduler: scheduler)
		let filename = UUID().uuidString
		let result = scheduler.start {
			sut.get(key: filename)
		}

		let expectedError = NSError(domain: "NSCocoaErrorDomain", code: 260)
		XCTAssertEqual(result.events.map(sanatizeError(event:)), [.error(201, expectedError)])
	}

	func testEmitsStoredValue() {
		let scheduler = TestScheduler(initialClock: 0)
		let disposeBag = DisposeBag()
		let tempDirectory = findTemporaryDirectory()
		let sut = DiskCache<String>(directory: tempDirectory, scheduler: scheduler)
		let filename = UUID().uuidString

		sut.set(key: filename, value: Data())
			.subscribe()
			.disposed(by: disposeBag)

		let result = scheduler.start {
			sut.get(key: filename)
		}

		XCTAssertEqual(result.events, [.next(201, Data()), .completed(201)])
	}
}

func findTemporaryDirectory() -> URL {
	if #available(iOS 10.0, *) {
		return FileManager.default.temporaryDirectory
	} else {
		return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
	}
}

func sanatizeError(event: Recorded<Event<Data>>) -> Recorded<Event<Data>> {
	switch event.value {
	case let .error(error):
		let error = error as NSError
		return Recorded(time: event.time, value: .error(NSError(domain: error.domain, code: error.code)))
	default:
		return event
	}
}
