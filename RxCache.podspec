Pod::Spec.new do |spec|
  spec.name          = "RxCache"
  spec.version       = "0.1.0"
  spec.summary       = "A caching library."
  spec.homepage      = "https://github.com/danielt1263/RxCache"
  spec.license       = "MIT"
  spec.author        = { "Daniel Tartaglia" => "danielt1263@gmail.com" }
  spec.ios.deployment_target = '9.0'
  spec.osx.deployment_target = '10.9'
  spec.watchos.deployment_target = '3.0'
  spec.tvos.deployment_target = '9.0'
  spec.source = { :git => "https://github.com/danielt1263/RxCache.git", :tag => "#{spec.version}" }
  spec.source_files  = "Sources/RxCache/*.swift"
  spec.swift_version = "5.6"
  spec.dependency "RxSwift", "~> 6.0"
end
