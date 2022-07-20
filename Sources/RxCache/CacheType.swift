import Foundation
import RxSwift

public protocol CacheType {
	associatedtype Key
	associatedtype Value

	func get(key: Key) -> Observable<Value>
	func set(key: Key, value: Value) -> Observable<Void>
}

extension CacheType {
	public func mapKeys<B>(_ fnInv: @escaping (B) -> Key) -> Cache<B, Value> {
		Cache<B, Value>(
			get: { key in
				self.get(key: fnInv(key))
			},
			set: { key, value in
				self.set(key: fnInv(key), value: value)
			}
		)
	}

	public func mapValues<B>(_ fn: @escaping (Value) throws -> B, _ fnInv: @escaping (B) throws -> Value) -> Cache<Key, B> {
		Cache(
			get: { key in
				self.get(key: key).map(fn)
			},
			set: { key, value in
				Observable.deferred {
					self.set(key: key, value: try fnInv(value))
				}
			}
		)
	}

	public func reuseInflight() -> Cache<Key, Value> where Key: Hashable {
		return Cache(
			get: reuseInflightGet(inner: self.get(key:)),
			set: self.set(key:value:)
		)
	}
}

public func compose<A, B>(_ a: A, _ b: B) -> Cache<A.Key, A.Value> where
A: CacheType, B: CacheType, A.Key == B.Key, A.Value == B.Value {
	Cache(
		get: composeGet(first: a.get(key:), second: b.get(key:), set: a.set(key:value:)),
		set: { key, value in
			Observable.zip(a.set(key: key, value: value), b.set(key: key, value: value))
				.map { _ in }
		}
	)
}

public enum CacheError: Error {
	case multiple(Error, Error)
	case identity
	case ram
}

func composeGet<Key, Value>(first: @escaping (Key) -> Observable<Value>, second: @escaping (Key) -> Observable<Value>, set: @escaping (Key, Value) -> Observable<Void>) -> (Key) -> Observable<Value> {
	{ key in
		first(key).catch { errorA in
			second(key).flatMap { value in
				Observable.zip(Observable.just(value), set(key, value).startWith(()))
					.map { $0.0 }
			}.catch { errorB in
				throw CacheError.multiple(errorA, errorB)
			}
		}
	}
}

func reuseInflightGet<Key, Value>(inner: @escaping (Key) -> Observable<Value>) -> (Key) -> Observable<Value> where Key: Hashable {
	var gets = [Key: Observable<Value>]()
	let lock = NSRecursiveLock()
	return { key in
		lock.lock(); defer { lock.unlock() }
		if let result = gets[key] {
			return result
		}

		let result = inner(key).do(onDispose: { [lock] in
			lock.lock(); defer { lock.unlock() }
			gets.removeValue(forKey: key)
		}).share(replay: 1)

		gets[key] = result
		return result
	}
}
