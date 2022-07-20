// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "RxCache",
	platforms: [
		.iOS(.v13),
	],
	products: [
		.library(
			name: "RxCache",
			targets: ["RxCache"]),
	],
	dependencies: [
		.package(
			url: "https://github.com/ReactiveX/RxSwift.git",
			.upToNextMajor(from: "6.0.0")
		)
	],
	targets: [
		.target(
			name: "RxCache",
			dependencies: [
				"RxSwift",
				.product(name: "RxCocoa", package: "RxSwift"),
			]
		),
		.testTarget(
			name: "RxCacheTests",
			dependencies: [
				"RxCache",
				.product(name: "RxTest", package: "RxSwift"),
			]
		),
	]
)
