platform :ios, '10.0'
source 'git@github.com:CocoaPods/Specs.git'
source 'git@github.com:applicaster/CocoaPods-Private.git'
source 'git@github.com:applicaster/CocoaPods.git'
source 'git@github.com:applicaster/PluginPresenter-iOS.git'
source 'git@github.com:applicaster/zapp-player-plugin-jw.git'

use_frameworks!

 pre_install do |installer|
   # workaround for https://github.com/CocoaPods/CocoaPods/issues/3289
   Pod::Installer::Xcode::TargetValidator.send(:define_method, :verify_no_static_framework_transitive_dependencies) {}
end

def shared_pods
    pod 'JWPlayerPlugin'
    pod 'PluginPresenter'
	#The Submodules and pinned versions below are needed to stop issues with clashing versions. Test before removing / updating.
    pod 'ZappPlugins', :path => 'Submodules/ZappPlugins/ZappPlugins.podspec'
    pod 'ApplicasterSDK', :path => 'Submodules/ApplicasterSDK/ApplicasterSDK.podspec'
    pod 'ZappAnalyticsPluginsSDK', '~> 8.0'
    pod 'ZappLoginPluginsSDK', '~> 8.0'
end

target 'Sport1Player' do
	shared_pods
end

 target 'Sport1PlayerTests' do
    inherit! :search_paths
    shared_pods
end
