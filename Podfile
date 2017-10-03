source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/crspybits/Specs.git'

platform :ios, '10.0'

target 'WhatDidILike' do
    use_frameworks!

    pod 'Fabric'
    pod 'Crashlytics'

    pod 'SMCoreLib', '~> 1.0'
	# pod 'SMCoreLib', :path => '../Common/SMCoreLib/'
	
	# Animated GIF's
	pod 'FLAnimatedImage', '~> 1.0'
	
    # 9/24/17; Dealing with Cocoapods inability to specify Swift versions...

	post_install do |installer|
	
		myTargets = ['SMCoreLib']
		
		installer.pods_project.targets.each do |target|
			if myTargets.include? target.name
				target.build_configurations.each do |config|
					config.build_settings['OTHER_SWIFT_FLAGS'] = '-DSWIFT4'
				end
			end
		end
	end
	
end
