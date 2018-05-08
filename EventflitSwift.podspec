Pod::Spec.new do |s|
  s.name             = 'EventflitSwift'
  s.version          = '0.1.0'
  s.summary          = 'A Eventflit client library in Swift'
  s.homepage         = 'https://github.com/eventflit/eventflit-websocket-swift'
  s.license          = 'MIT'
  s.author           = { "Hamilton Chapman" => "hamchapman@gmail.com" }
  s.source           = { git: "https://github.com/eventflit/eventflit-websocket-swift.git", tag: s.version.to_s }
  s.social_media_url = 'https://twitter.com/eventflit'

  s.requires_arc = true
  s.source_files = 'Sources/*.swift'

  s.dependency 'CryptoSwift', '~> 0.9.0'
  s.dependency 'ReachabilitySwift', '~> 4.1.0'
  s.dependency 'TaskQueue', '~> 1.1.1'
  s.dependency 'StarscreamFork', '~> 3.0.6'

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '9.0'
end
