//
//  Cache.swift
//
//  Created by Daniel Tartaglia on 20 Jul 2022.
//  Copyright © 2024 Daniel Tartaglia. MIT License.
//

import RxSwift

public final class Cache<Key, Value>: CacheType {
	private let _get: (Key) -> Observable<Value>
	private let _set: (Key, Value) -> Observable<Void>

	public init(
		get: @escaping (Key) -> Observable<Value> = { _ in .error(CacheError.identity) },
		set: @escaping (Key, Value) -> Observable<Void> = { _, _ in .just(()) }
	) {
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
