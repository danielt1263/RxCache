//
//  RamCache.swift
//
//  Created by Daniel Tartaglia on 20 Jul 2022.
//  Copyright © 2024 Daniel Tartaglia. MIT License.
//

import Foundation
import RxSwift

public final class RamCache<Key, Value>: CacheType where Key: Hashable {
	private let lock = NSRecursiveLock()
	private var storage = [Key: Value]()

	public init() { }

	public func remove(key: Key) {
		lock.lock(); defer { lock.unlock() }
		storage.removeValue(forKey: key)
	}

	public func clear() {
		lock.lock(); defer { lock.unlock() }
		storage = [:]
	}

	public func get(key: Key) -> Observable<Value> {
		.deferred { [lock, storage] in
			lock.lock(); defer { lock.unlock() }
			guard let value = storage[key] else {
				return .error(CacheError.valueNotInCache)
			}
			return .just(value)
		}
	}

	public func set(key: Key, value: Value) -> Observable<Void> {
		.deferred { [self, lock] in
			lock.lock(); defer { lock.unlock() }
			self.storage[key] = value
			return .just(())
		}
	}
}
