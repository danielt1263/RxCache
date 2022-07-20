import RxSwift

public final class IdentityCache<Key, Value>: CacheType {
	public func get(key: Key) -> Observable<Value> {
		.error(CacheError.identity)
	}

	public func set(key: Key, value: Value) -> Observable<Void> {
		.just(())
	}
}
