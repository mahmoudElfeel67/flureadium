#
# macOS podspec for flureadium with full Readium support.
# Readium pod dependencies are declared in the app's Podfile via podspec: URLs
# (they're not on public CocoaPods CDN).
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

  s.platform = :osx, '13.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
