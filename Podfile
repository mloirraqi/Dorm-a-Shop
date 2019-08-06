# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Dorm-a-Shop' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Dorm-a-Shop
  pod 'Parse'
  pod 'Parse/UI'
pod 'ParseLiveQuery'
  pod 'DateTools'
  pod 'MBProgressHUD', '~> 1.0.0'
  pod 'GoogleMaps'
  pod 'GooglePlacePicker'
  pod 'GooglePlaces'
  pod 'TwilioChatClient', '2.2.0'
  pod 'SDWebImage'
  
  target 'Dorm-a-ShopTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'Dorm-a-ShopUITests' do
    inherit! :search_paths
    # Pods for testing
  end

  pre_install do |installer|
	installer.analysis_result.specifications.each do |s|
        if s.name == 'Bolts-Swift'
            s.swift_version = '4.2'
        end
    end
  end
end