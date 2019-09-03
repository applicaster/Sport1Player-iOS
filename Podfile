platform :ios, '10.0'
source 'git@github.com:CocoaPods/Specs.git'
source 'git@github.com:applicaster/CocoaPods-Private.git'
source 'git@github.com:applicaster/CocoaPods.git'
source 'git@github.com:applicaster/PluginPresenter-iOS.git'
source 'git@github.com:applicaster/GermanAgeVerification-iOS.git'

use_frameworks!

 pre_install do |installer|
   # workaround for https://github.com/CocoaPods/CocoaPods/issues/3289
   Pod::Installer::Xcode::TargetValidator.send(:define_method, :verify_no_static_framework_transitive_dependencies) {}
end

def shared_pods
	pod 'JWPlayerPlugin'
    pod 'ZappPlugins'
	pod 'ApplicasterSDK'
	pod 'PluginPresenter'
	pod 'GermanAgeVerification'
end

target 'Sport1Player' do
	shared_pods
end

 target 'Sport1PlayerTests' do
    inherit! :search_paths
    shared_pods
  end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '4.2'
            config.build_settings['ENABLE_BITCODE'] = 'YES'
            config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ""
            config.build_settings['CODE_SIGNING_REQUIRED'] = "NO"
            config.build_settings['CODE_SIGNING_ALLOWED'] = "NO"
            config.build_settings['OTHER_CFLAGS'] = ['$(inherited)', "-fembed-bitcode"]
            config.build_settings['BITCODE_GENERATION_MODE']  = "bitcode"
        end
    end
end
