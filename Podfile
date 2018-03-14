source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/crspybits/Specs.git'

platform :ios, '10.0'

target 'WhatDidILike' do
    use_frameworks!

    pod 'Fabric'
    pod 'Crashlytics'

    pod 'SMCoreLib', '~> 1.2'
	# pod 'SMCoreLib', :path => '../Common/SMCoreLib/'
	
	# Animated GIF's
	pod 'FLAnimatedImage', '~> 1.0'
	
	# Smiley ratings
	pod 'TTGEmojiRate', '~> 0.3'
	# pod 'TTGEmojiRate', :git => 'https://github.com/crspybits/TTGEmojiRate.git'
	# pod 'TTGEmojiRate', :path => '../TTGEmojiRate'

	# Labeled switch
	pod 'DGRunkeeperSwitch', '~> 1.1'
	
	# pod 'ImageSlideshow', :git => 'https://github.com/crspybits/ImageSlideshow.git'
	# pod 'ImageSlideshow', '~> 1.4'
	pod 'ImageSlideshow', :path => '../ImageSlideshow'

	pod 'BEMCheckBox', '~> 1.0'
	
	# progress indicator for converting from old format data.
	pod 'M13ProgressSuite', '~> 1.2'
	
    # 9/24/17; Dealing with Cocoapods inability to specify Swift versions...

	post_install do |installer|
	
		swift4Flag = ['SMCoreLib']
		
		installer.pods_project.targets.each do |target|
			if swift4Flag.include? target.name
				target.build_configurations.each do |config|
					config.build_settings['OTHER_SWIFT_FLAGS'] = '-DSWIFT4'
				end
			end
		end
		
		swiftVersion3_2 = ['DGRunkeeperSwitch']
		
		installer.pods_project.targets.each do |target|
			if swiftVersion3_2.include? target.name
				target.build_configurations.each do |config|
					config.build_settings['SWIFT_VERSION'] = '3.2'
				end
			end
		end
	end
end
