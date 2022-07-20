import RxSwift
import RxTest
import XCTest
@testable import RxCache

final class ReuseInflightTests: XCTestCase {
	var scheduler: TestScheduler!
	var disposeBag: DisposeBag!
	var sink1: TestableObserver<String>!
	var sink2: TestableObserver<String>!
	var getCallCount: Int = 0
	var setCallCount: Int = 0
	var fakeCache: Cache<String, String>!
	var sut: ((String) -> Observable<String>)!

	override func setUp() {
		scheduler = TestScheduler(initialClock: 0)
		disposeBag = DisposeBag()
		sink1 = scheduler.createObserver(String.self)
		sink2 = scheduler.createObserver(String.self)
		getCallCount = 0
		fakeCache = Cache<String, String>(
			get: { _ in
				self.getCallCount += 1
				return Observable.just("count \(self.getCallCount)").delay(.seconds(3), scheduler: self.scheduler)
			},
			set: { _, _ in
				self.setCallCount += 1
				return Observable.just(())
			}
		)

		sut = reuseInflightGet(inner: fakeCache.get(key:))
	}

	func testPoolsCalls() {
		sut("hello")
			.subscribe(sink1)
			.disposed(by: disposeBag)

		scheduler.scheduleAt(2) {
			self.sut("hello")
				.subscribe(self.sink2)
				.disposed(by: self.disposeBag)
		}
		scheduler.start()

		XCTAssertEqual(getCallCount, 1)
		XCTAssertEqual(sink1.events.count, 2)
		XCTAssertEqual(sink1.events, sink2.events)
	}

	func testOnlyPoolsIncompleteCalls() {
		sut("hello")
			.subscribe(sink1)
			.disposed(by: disposeBag)

		scheduler.scheduleAt(5) {
			self.sut("hello")
				.subscribe(self.sink2)
				.disposed(by: self.disposeBag)
		}
		scheduler.start()

		XCTAssertEqual(getCallCount, 2)
		XCTAssertEqual(sink1.events, [.next(3, "count 1"), .completed(4)])
		XCTAssertEqual(sink2.events, [.next(8, "count 2"), .completed(9)])
	}

	func testRaceConditionReturnsValue() {
		sut("hello")
			.subscribe(sink1)
			.disposed(by: disposeBag)

		scheduler.scheduleAt(4) {
			self.sut("hello")
				.subscribe(self.sink2)
				.disposed(by: self.disposeBag)
		}
		scheduler.start()

		XCTAssertEqual(getCallCount, 1)
		XCTAssertEqual(sink1.events, [.next(3, "count 1"), .completed(4)])
		XCTAssertEqual(sink2.events, [.next(4, "count 1"), .completed(4)])
	}

	func testDifferentKeys() {
		sut("hello")
			.subscribe(sink1)
			.disposed(by: disposeBag)

		sut("world")
			.subscribe(sink2)
			.disposed(by: disposeBag)

		scheduler.start()

		XCTAssertEqual(sink1.events, [.next(3, "count 1"), .completed(4)])
		XCTAssertEqual(sink2.events, [.next(3, "count 2"), .completed(4)])
	}
}

