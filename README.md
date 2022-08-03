# RxCache

A caching library using RxSwift and inspired by [Brandon Kase's presentation: "Composable Caching in Swift"](https://youtu.be/8uqXuEZLyUU).

A simple example of use:
```swift
func createDataGetter<Result>(
	for type: Result.Type
) -> (URLRequest) -> Observable<Result> where Result: Codable {
	createDataGetter(
		for: type,
		decode: { try JSONDecoder().decode(Result.self, from: $0) },
		encode: { try JSONEncoder().encode($0) }
	)
}

func createDataGetter<Result>(
	for type: Result.Type,
	decode: @escaping (Data) throws -> Result,
	encode: @escaping (Result) throws -> Data
) -> (URLRequest) -> Observable<Result> {
	let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
	let scheduler = ConcurrentDispatchQueueScheduler(qos: .default)
	let ram = RamCache<URLRequest, Result>()
	let disk = DiskCache<URLRequest>(directory: directory, scheduler: scheduler)
	let network = Cache(get: URLSession.shared.rx.data(request:))

	return compose(ram, compose(disk, network).mapValues(decode, encode))
		.reuseInflight()
		.get(key:)
}
```
