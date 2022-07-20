import Foundation
import RxCocoa
import RxSwift

public final class NetworkCache: CacheType {
	let data: (URLRequest) -> Observable<Data>

	public init(data: @escaping (URLRequest) -> Observable<Data> = URLSession.shared.rx.data(request:)) {
		self.data = data
	}

	public func get(key: URLRequest) -> Observable<Data> {
		data(key)
	}

	public func set(key: URLRequest, value: Data) -> Observable<Void> {
		precondition(key.httpMethod != "GET")
		var request = key
		request.httpBody = value
		return data(key)
			.map { _ in }
	}
}
