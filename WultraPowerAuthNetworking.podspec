Pod::Spec.new do |s|
  s.cocoapods_version   = '>= 1.10'
  s.name                = "WultraPowerAuthNetworking"
  s.version             = '1.2.0'
  s.license             = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.summary             = "PowerAuth Networking by Wultra"
  s.homepage            = "https://www.wultra.com/"
  s.social_media_url    = 'https://twitter.com/wultra'
  s.author              = { 'Wultra s.r.o.' => 'support@wultra.com' }
  s.source              = { :git => 'https://github.com/wultra/networking-apple.git', :tag => s.version }
  s.source_files        = 'Sources/WultraPowerauthNetworking/**/*.swift'
  s.platform            = :ios
  s.swift_version       = "5.7"
  s.ios.deployment_target  = '11.0'

  s.dependency 'PowerAuth2', '>= 1.7'
end
