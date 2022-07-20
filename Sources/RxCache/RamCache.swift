import RxSwift

public final class RamCache<Key, Value>: CacheType where Key: Hashable {
	private var storage = [Key: Value]()

	public init() { }
	
	public func get(key: Key) -> Observable<Value> {
		guard let value = storage[key] else {
			return .error(CacheError.ram)
		}
		return .just(value)
	}

	public func set(key: Key, value: Value) -> Observable<Void> {
		storage[key] = value
		return .just(())
	}
}
