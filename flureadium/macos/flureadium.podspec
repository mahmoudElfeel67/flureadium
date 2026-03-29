#
# macOS podspec for flureadium — ported from iOS with Readium dependencies.
# Run `pod lib lint flureadium.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flureadium'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin wrapper for Readium toolkits (macOS).'
  s.description      = <<-DESC
Flutter plugin wrapper for Readium toolkits, ported to macOS.
Provides EPUB, PDF, and audiobook reading capabilities.
                       DESC
  s.homepage         = 'http://github.com/mahmoudElfeel67/flureadium'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Mahmoud Elfeel' => 'mahmoudelfeel67@gmail.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*.swift'

  s.dependency 'FlutterMacOS'
  s.dependency 'ReadiumShared', '~> 3.5.0'
  s.dependency 'ReadiumStreamer', '~> 3.5.0'
  s.dependency 'ReadiumNavigator', '~> 3.5.0'
  s.dependency 'ReadiumOPDS', '~> 3.5.0'
  s.dependency 'ReadiumAdapterGCDWebServer', '~> 3.5.0'
  s.dependency 'ReadiumInternal', '~> 3.5.0'
  # s.dependency 'ReadiumLCP', '~> 3.5.0'

  s.platform = :osx, '13.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
