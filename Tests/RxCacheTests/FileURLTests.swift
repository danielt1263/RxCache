@testable import RxCache
import XCTest

final class FileURLTests: XCTestCase {
	func test() {
		let sut = FileURL(rawValue: URL(string: "https://foo.bar")!)
		XCTAssertNil(sut)
	}
}
