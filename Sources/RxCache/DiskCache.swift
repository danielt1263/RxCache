//
//  DiskCache.swift
//
//  Created by Daniel Tartaglia on 20 Jul 2022.
//  Copyright © 2022 Daniel Tartaglia. MIT License.
//

import Foundation
import RxSwift

public final class DiskCache<Key>: CacheType where Key: CustomStringConvertible {
	let directory: URL
	let scheduler: SchedulerType

	public init(directory: URL, scheduler: SchedulerType) {
		self.directory = directory
		self.scheduler = scheduler
	}

	public func get(key: Key) -> Observable<Data> {
		.deferred { [directory] in
			let url = directory.appendingPathComponent(
				key.description.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
			)
			return .just(try Data(contentsOf: url))
		}
		.subscribe(on: scheduler)
	}

	public func set(key: Key, value: Data) -> Observable<Void> {
		.deferred { [directory] in
			let url = directory.appendingPathComponent(
				key.description.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
			)
			return .just(try value.write(to: url))
		}
		.subscribe(on: scheduler)
	}
}
