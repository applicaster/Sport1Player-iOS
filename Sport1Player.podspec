Pod::Spec.new do |s|
  s.name             = "Sport1Player"
  s.version          = '1.1.2'
  s.summary          = "Sport1Player"
  s.description      = <<-DESC
                        Player for Sport1, based off JWPlayer.
                       DESC
  s.homepage         = "https://github.com/applicaster/Sport1Player-iOS.git"
  s.license          = 'CMPS'
  s.author           = { "cmps" => "o.stowell@applicaster.com" }
  s.source           = { :git => "git@github.com:applicaster/Sport1Player-iOS.git", :tag => s.version.to_s }

  s.platform     = :ios, '10.0'
  s.requires_arc = true

  s.public_header_files = 'Sport1Player/**/*.h'
  s.source_files = 'Sport1Player/**/*.{h,m,swift}'
  s.resources = [
    'Sport1Player/Resources/**/*.plist',
    'Sport1Player/Resources/**/*.xib'
  ]

  s.xcconfig =  { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
                  'ENABLE_BITCODE' => 'YES',
                  'OTHER_CFLAGS'  => '-fembed-bitcode',
                  'OTHER_LDFLAGS' => '$(inherited) -framework "JWPlayer_iOS_SDK"'
                  }

  s.dependency 'ZappPlugins'
  s.dependency 'JWPlayerPlugin'
  s.dependency 'PluginPresenter'

end
