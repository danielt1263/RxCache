import CommonCrypto
import Foundation
import RxSwift

public final class DiskCache<Key>: CacheType where Key: CustomStringConvertible {
	let directory: URL
	let scheduler: SchedulerType

	public init(directory: FileURL, scheduler: SchedulerType) {
		self.directory = directory.rawValue
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

public struct FileURL: RawRepresentable {
	public let rawValue: URL

	public init?(rawValue: URL) {
		guard rawValue.scheme == "file" else { return nil }
		self.rawValue = rawValue
	}
}
