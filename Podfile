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
    pod 'ZappPlugins', '9.3.0'
	pod 'JWPlayerPlugin'
	pod 'PluginPresenter'
end

target 'Sport1Player' do
	shared_pods
end

 target 'Sport1PlayerTests' do
    inherit! :search_paths
    shared_pods
end
