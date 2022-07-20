@testable import RxCache
import RxSwift
import RxTest
import XCTest

final class NetworkCacheTests: XCTestCase {
	func testGetMakesRequest() {
		let scheduler = TestScheduler(initialClock: 0)
		let expectedRequest = URLRequest(url: URL(string: "https://foo.bar")!)
		var mockCalled = false
		let mock: (URLRequest) -> Observable<Data> = { request in
			XCTAssertEqual(request, expectedRequest)
			mockCalled = true
			return .just(Data())
		}
		let sut = NetworkCache(data: mock)

		let result = scheduler.start {
			sut.get(key: expectedRequest)
		}

		XCTAssertTrue(mockCalled)
		XCTAssertEqual(result.events, [.next(200, Data()), .completed(200)])
	}
}
