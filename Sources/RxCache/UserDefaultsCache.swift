//
//  UserDefaultsCache.swift
//
//  Created by Daniel Tartaglia on 11 Feb 2024.
//  Copyright © 2024 Daniel Tartaglia. MIT License.
//

import Foundation
import RxSwift

public final class UserDefaultsCache<Key>: CacheType where Key: CustomStringConvertible {
	private let defaults: UserDefaults

	init(defaults: UserDefaults) {
		self.defaults = defaults
	}

	public func get(key: Key) -> Observable<Data> {
		.deferred { [defaults] in
			guard let data = defaults.data(forKey: key.description)
			else { throw CacheError.valueNotInCache }
			return .just(data)
		}
	}

	public func set(key: Key, value: Data) -> Observable<Void> {
		.deferred { [defaults] in
			defaults.setValue(value, forKey: key.description)
			return .just(())
		}
	}
}
