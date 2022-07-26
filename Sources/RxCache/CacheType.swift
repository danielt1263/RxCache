//
//  CacheType.swift
//
//  Created by Daniel Tartaglia on 20 Jul 2022.
//  Copyright © 2022 Daniel Tartaglia. MIT License.
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
		return Cache(
			get: InflightReuser(inner: self.get(key:)).get(key:),
			set: self.set(key:value:)
		)
	}
}

public func compose<A, B>(_ first: A, _ second: B) -> Cache<A.Key, A.Value>
where A: CacheType, B: CacheType, A.Key == B.Key, A.Value == B.Value {
	Cache(
		get: { key in
			first.get(key: key).catch { errorA in
				second.get(key: key).flatMap { value in
					Observable.zip(first.set(key: key, value: value).startWith(()), Observable.just(value)) { $1 }
				}.catch { throw CacheError.multiple(errorA, $0) }
			}
		},
		set: { key, value in
			Observable.zip(first.set(key: key, value: value), second.set(key: key, value: value)) { _, _ in }
		}
	)
}

public enum CacheError: Error {
	case multiple(Error, Error)
	case identity
	case ram
}

final class InflightReuser<Key, Value> where Key: Hashable {
	let inner: (Key) -> Observable<Value>
	let lock = NSRecursiveLock()
	private(set) var gets = [Key: Observable<Value>]()

	init(inner: @escaping (Key) -> Observable<Value>) {
		self.inner = inner
	}

	func get(key: Key) -> Observable<Value> {
		lock.lock(); defer { lock.unlock() }
		if let result = gets[key] {
			return result
		}

		let result = inner(key).do(onDispose: { [lock] in
			lock.lock(); defer { lock.unlock() }
			self.gets.removeValue(forKey: key)
		}).share(replay: 1)

		gets[key] = result
		return result
	}
}
