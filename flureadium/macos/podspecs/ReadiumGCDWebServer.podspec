Pod::Spec.new do |s|
  s.name     = 'ReadiumGCDWebServer'
  s.version  = '4.0.1'
  s.author   =  { 'Pierre-Olivier Latour' => 'info@pol-online.net' }
  s.license  = { :type => 'BSD', :file => 'LICENSE' }
  s.homepage = 'https://github.com/readium/GCDWebServer'
  s.summary  = 'Lightweight GCD based HTTP server for OS X & iOS'

  s.source   = { :git => 'https://github.com/readium/GCDWebServer.git', :tag => s.version.to_s }
  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '11.0'
  s.requires_arc = true

  s.default_subspec = 'Core'

  s.subspec 'Core' do |cs|
    cs.source_files = 'GCDWebServer/**/*.{h,m}'
    cs.exclude_files = 'GCDWebServer/include/*'
    cs.requires_arc = true
    cs.library = 'z'
    cs.frameworks = 'CFNetwork'
  end
end
