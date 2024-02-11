//
//  CacheType.swift
//
//  Created by Daniel Tartaglia on 20 Jul 2022.
//  Copyright © 2024 Daniel Tartaglia. MIT License.
//

import Foundation
import RxSwift

public protocol CacheType {
	associatedtype Key
	associatedtype Value

	func get(key: Key) -> Observable<Value>
	func set(key: Key, value: Value) -> Observable<Void>
}

extension CacheType {
	public func mapKeys<B>(_ funInv: @escaping (B) throws -> Key) -> Cache<B, Value> {
		Cache<B, Value>(
			get: { key in
				Observable.deferred { self.get(key: try funInv(key)) }
			},
			set: { key, value in
				Observable.deferred { self.set(key: try funInv(key), value: value) }
			}
		)
	}

	public func mapValues<B>(
		_ fun: @escaping (Value) throws -> B,
		_ funInv: @escaping (B) throws -> Value
	) -> Cache<Key, B> {
		Cache(
			get: { self.get(key: $0).map { try fun($0) } },
			set: { key, value in
				Observable.deferred { self.set(key: key, value: try funInv(value)) }
			}
		)
	}

	public func reuseInflight() -> Cache<Key, Value> where Key: Hashable {
		Cache(
			get: RxCache.reuseInFlight(inner: get(key:)),
			set: set(key:value:)
		)
	}

	public func reuseInflight() -> Cache<Key, Value> where Key: Equatable {
		reuseInFlight(comp: { $0 == $1 })
	}

	public func reuseInflight() -> Cache<Key, Value> where Key == Void {
		reuseInFlight(comp: { _, _ in true })
	}

	public func reuseInFlight(comp: @escaping (Key, Key) -> Bool) -> Cache<Key, Value> {
		Cache(
			get: RxCache.reuseInFlight(comp: comp, inner: get(key:)),
			set: set(key:value:)
		)
	}
}

public func compose<A, B>(_ lhs: A, _ rhs: B) -> Cache<A.Key, A.Value>
where A: CacheType, B: CacheType, A.Key == B.Key, A.Value == B.Value {
	Cache(
		get: { key in
			lhs.get(key: key)
				.catch { lhsError in
					rhs.get(key: key)
						.flatMap { value in
							Observable.zip(lhs.set(key: key, value: value).startWith(()), Observable.just(value)) { $1 }
						}
						.catch { throw CacheError.multiple(lhsError, $0) }
				}
		},
		set: { key, value in
			Observable.zip(lhs.set(key: key, value: value), rhs.set(key: key, value: value)) { _, _ in }
		}
	)
}

public enum CacheError: Error {
	case multiple(Error, Error)
	case identity
	case valueNotInCache
}

func reuseInFlight<Key, Value>(inner: @escaping (Key) -> Observable<Value>) -> (Key) -> Observable<Value>
where Key: Hashable {
	let lock = NSRecursiveLock()
	var gets = [Key: Observable<Value>]()
	return { key in
		lock.lock(); defer { lock.unlock() }
		if let result = gets[key] {
			return result
		}

		let result = inner(key).do(onDispose: { [lock] in
			lock.lock(); defer { lock.unlock() }
			gets.removeValue(forKey: key)
		})
			.share(replay: 1)

		gets[key] = result
		return result
	}
}

func reuseInFlight<Key, Value>(comp: @escaping (Key, Key) -> Bool, inner: @escaping (Key) -> Observable<Value>) -> (Key) -> Observable<Value> {
	let lock = NSRecursiveLock()
	var gets = [(Key, Observable<Value>)]()
	return { key in
		lock.lock(); defer { lock.unlock() }
		if let result = gets.first(where: { comp($0.0, key) })?.1 {
			return result
		}

		let result = inner(key).do(onDispose: { [lock] in
			lock.lock(); defer { lock.unlock() }
			if let index = gets.firstIndex(where: { comp($0.0, key) }) {
				gets.remove(at: index)
			}
		})
			.share(replay: 1)

		gets.append((key, result))
		return result
	}
}
