//
//  UserDefaultsCache.swift
//
//  Created by Daniel Tartaglia on 11 Feb 2024.
//  Copyright © 2024 Daniel Tartaglia. MIT License.
//

import Foundation
import RxSwift

public final class UserDefaultsCache<Key, Value>: CacheType where Key: CustomStringConvertible, Value: Codable {

	private let defaults: UserDefaults

	init(defaults: UserDefaults) {
		self.defaults = defaults
	}

	public func get(key: Key) -> RxSwift.Observable<Value> {
		.deferred { [defaults] in
			guard let data = defaults.data(forKey: key.description) else { throw CacheError.valueNotInCache }
			return .just(try JSONDecoder().decode(Value.self, from: data))
		}
	}

	public func set(key: Key, value: Value) -> RxSwift.Observable<Void> {
		.deferred { [defaults] in
			let data = try JSONEncoder().encode(value)
			defaults.setValue(data, forKey: key.description)
			return .just(())
		}
	}
}
