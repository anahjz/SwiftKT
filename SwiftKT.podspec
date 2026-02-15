Pod::Spec.new do |spec|
  spec.name          = 'SwiftKT'
  spec.version       = '1.0.0'
  spec.summary       = 'Kotlin String API in Swift'
  spec.description   = 'Swift port of Kotlin standard library String API. Use .kotlin on any String for Kotlin-style methods (trim, substringBefore, split, etc.) — same names, Swift 5.9+, no dependencies.'
  spec.homepage      = 'https://github.com/YOUR_ORG/SwiftKT'
  spec.license       = { :type => 'MIT', :file => 'LICENSE' }
  spec.author        = { 'SwiftKT' => 'your-email@example.com' }
  spec.source        = { :git => 'https://github.com/YOUR_ORG/SwiftKT.git', :tag => "v#{spec.version}" }
  spec.source_files  = 'Sources/SwiftKT/**/*.swift'
  spec.swift_versions = '5.9'
  spec.ios.deployment_target     = '16.0'
  spec.macos.deployment_target   = '13.0'
  spec.tvos.deployment_target    = '16.0'
  spec.watchos.deployment_target = '9.0'
end
