import RxSwift

public final class Cache<Key, Value>: CacheType {
	private let _get: (Key) -> Observable<Value>
	private let _set: (Key, Value) -> Observable<Void>

	init(get: @escaping (Key) -> Observable<Value>, set: @escaping (Key, Value) -> Observable<Void>) {
		_get = get
		_set = set
	}

	public func get(key: Key) -> Observable<Value> {
		_get(key)
	}

	public func set(key: Key, value: Value) -> Observable<Void> {
		_set(key, value)
	}
}
