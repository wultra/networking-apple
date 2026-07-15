Pod::Spec.new do |s|
  s.cocoapods_version   = '>= 1.10'
  s.name                = "WultraPowerAuthNetworking"
  s.version             = '2.0.0-RC1'
  s.license             = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.summary             = "PowerAuth Networking by Wultra"
  s.homepage            = "https://www.wultra.com/"
  s.social_media_url    = 'https://twitter.com/wultra'
  s.author              = { 'Wultra s.r.o.' => 'support@wultra.com' }
  s.source              = { :git => 'https://github.com/wultra/networking-apple.git', :tag => s.version }
  s.source_files        = 'Sources/WultraPowerauthNetworking/**/*.swift'
  s.platform            = :ios
  s.swift_version       = "5.9"
  s.ios.deployment_target  = '13.0'

  s.dependency 'PowerAuth2', '2.0.0-RC1'
end
