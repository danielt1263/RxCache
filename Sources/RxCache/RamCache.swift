//
//  RamCache.swift
//
//  Created by Daniel Tartaglia on 20 Jul 2022.
//  Copyright © 2022 Daniel Tartaglia. MIT License.
//

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
