Pod::Spec.new do |s|
  s.name                = "WultraPowerAuthNetworking"
  s.version             = '%DEPLOY_VERSION%'
  s.summary             = "PowerAuth Networking by Wultra"
  s.homepage            = "https://www.wultra.com/"
  s.social_media_url    = 'https://twitter.com/wultra'
  s.author              = { 'Wultra s.r.o.' => 'support@wultra.com' }
  s.source              = { :git => 'https://github.com/wultra/networking-apple.git', :tag => s.version }
  s.source_files        = 'WultraPowerAuthNetworking/**/*.swift'
  s.vendored_frameworks = "WultraPowerAuthNetworking.xcframework"
  s.platform            = :ios
  s.swift_version       = "5.0"
  s.ios.deployment_target  = '10.0'

  s.dependency 'PowerAuth2', '>= 1.6'
end