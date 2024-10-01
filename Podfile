platform :ios, '13.0'
use_frameworks!
inhibit_all_warnings!

system("
			 echo

			 RestaurantSDK_PATH='./SDK/RestaurantSDK'
			 RestaurantSDK_BRANCH=SDK
			 RestaurantSDK_REVISION=caba7d16
			 RestaurantSDK_REPO=https://git.lgn.me/technolab/technolab/wrf.git
             
             cdToRepoRootIfNeeded() {
                if [[ ! -z $CI ]]; then
                    cd $CI_PRIMARY_REPOSITORY_PATH
                fi
             }

			 installSubproject() {
				 local name=$1
				 local path=$2
				 local remote=$3
				 local branch=$4
				 local revision=$5
                 
                 cdToRepoRootIfNeeded

				 mkdir -p ./SDK

			   echo \"WILL INSTALL $name\"

				 if [ -d $path ]; then
					 echo \"$path directory exists, save work and checkout\"
					 cd $path;
					 git add .;
					 git stash save \"Checked out $branch $revision on $(date)\";

					 git fetch origin;
					 git checkout $branch; git pull;
					 git reset --hard $revision;
				 else
					 git clone $remote $path
					 cd $path;
					 git checkout $branch; git pull;
					 git reset --hard $revision;
				 fi

				 pod install
				 cd ../../
                 cdToRepoRootIfNeeded
			 }

			 installSubproject 'RestaurantSDK' $RestaurantSDK_PATH $RestaurantSDK_REPO $RestaurantSDK_BRANCH $RestaurantSDK_REVISION
")

workspace 'Prime.xcworkspace'
project 'Prime.xcodeproj'
project './SDK/RestaurantSDK/RestaurantSDK.xcodeproj'

def shared_pods
	pod 'RealmSwift', '~> 10.7'
	pod 'Branch'
    pod 'SwiftLint'
	pod 'PromiseKit', '~> 6.13'
	pod 'SnapKit', '~> 5.0'
	pod 'Nuke', '~> 10.7'
	pod 'FloatingPanel', :git => 'https://github.com/Hayk91K/FloatingPanel', :commit => 'da1aedf3d1c9ed8e16c2cada819ec78a463f3433'
	pod 'IQKeyboardManagerSwift', '~> 6.5'
	pod 'Alamofire', '~> 4.8'
	pod 'SwiftKeychainWrapper', '~> 3.4'
	pod 'Firebase/Messaging', '~> 10.22'
	pod 'Firebase/Crashlytics', '~> 10.22'
	pod 'Firebase/Database', '~> 10.22'
	pod 'FirebaseAppCheck', '~> 10.22'
	pod 'YandexMobileMetrica/Dynamic/Core', '~> 3.8'
	pod 'GoogleUtilities', '~> 7.7'
end

def prime_pods
	pod 'FSCalendar'
	pod 'DeckTransition', '~> 2.2'
	pod 'PhoneNumberKit', '~> 3.3'
	pod 'XLPagerTabStrip', '~> 9.0'
	pod 'SwiftMaskText', '~> 2.0'
  pod "JMMaskTextField-Swift"
	pod 'Firebase/Core', '~> 10.22'
	pod 'DeviceKit'
end

def restaurant_pods
	pod 'GoogleMaps', '~> 6.2'
	pod 'DeviceKit'
	pod 'SkyFloatingLabelTextField', '~> 3.7'
	pod 'JTAppleCalendar', '~> 7.1'
	pod 'Tabman', '~> 2.13'
	pod 'MBProgressHUD', '~> 1.1'
	pod 'CTPanoramaView', '~> 1.3'
	pod 'AnyFormatKit', '~> 2.0'
	pod 'Firebase/Analytics', '~> 10.22'
	pod 'TagListView', '~> 1.4'
	pod 'YoutubeKit', '~> 0.5'
	pod 'libPhoneNumber-iOS'
end

def appex_pods
  pod 'Firebase/Crashlytics', '~> 10.22'
  pod 'Firebase/Database', '~> 10.22'
	pod 'FirebaseAppCheck', '~> 10.22'
  pod 'SwiftKeychainWrapper', '~> 3.4'
  pod 'GoogleUtilities', '~> 7.7'
	pod 'DeviceKit'
end


target 'RestaurantSDK' do
	project './SDK/RestaurantSDK/RestaurantSDK.xcodeproj'
	restaurant_pods
	shared_pods
end

target 'Prime' do
	project 'Prime.xcodeproj'
	prime_pods
	shared_pods
	restaurant_pods
end

target 'Prime-Sharing' do
	project 'Prime.xcodeproj'
	pod 'SnapKit', '~> 5.0'
  appex_pods
end

target 'Prime-RichPushes' do
	project 'Prime.xcodeproj'
  appex_pods
end

target 'Prime-Tests' do
	project 'Prime.xcodeproj'
	prime_pods
	shared_pods
	restaurant_pods
end

target 'Aeroflot' do
	project 'Prime.xcodeproj'
	prime_pods
	shared_pods
	restaurant_pods
end

#target 'Aeroflot-Sharing' do
#	project 'Prime.xcodeproj'
#	pod 'SnapKit', '~> 5.0'
#  appex_pods
#end

target 'Aeroflot-Tests' do
	project 'Prime.xcodeproj'
	prime_pods
	shared_pods
	restaurant_pods
end

target 'Aeroflot-RichPushes' do
	project 'Prime.xcodeproj'
  appex_pods
end
			 
target 'Prime Club' do
  project 'Prime.xcodeproj'
  prime_pods
  shared_pods
  restaurant_pods
end
              
target 'Prime Club-Sharing' do
  project 'Prime.xcodeproj'
  pod 'SnapKit', '~> 5.0'
  appex_pods
end
      
target 'Prime Club-RichPushes' do
  project 'Prime.xcodeproj'
  appex_pods
end
       
target 'PRIME Italy' do
  project 'Prime.xcodeproj'
  prime_pods
  shared_pods
  restaurant_pods
end
              
target 'PrimeItaly-Sharing' do
  project 'Prime.xcodeproj'
  pod 'SnapKit', '~> 5.0'
  appex_pods
end
      
target 'PrimeItaly-RichPushes' do
  project 'Prime.xcodeproj'
  appex_pods
end
       
target 'VTB' do
  project 'Prime.xcodeproj'
  prime_pods
  shared_pods
  restaurant_pods
end
              
target 'VTB-Sharing' do
  project 'Prime.xcodeproj'
  pod 'SnapKit', '~> 5.0'
  appex_pods
end

target 'VTB-RichPushes' do
  project 'Prime.xcodeproj'
  appex_pods
end

target 'Tinek' do
	project 'Prime.xcodeproj'
	prime_pods
	shared_pods
	restaurant_pods
end

target 'Tinek-Sharing' do
	project 'Prime.xcodeproj'
	pod 'SnapKit', '~> 5.0'
	appex_pods
end

target 'Tinek-RichPushes' do
	project 'Prime.xcodeproj'
	appex_pods
end

post_install do |installer|
	installer.pods_project.targets.each do |t|
		t.build_configurations.each do |config|
			config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
			config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
			config.build_settings["DEVELOPMENT_TEAM"] = "DBT4Q8Z5BS"
		end
	end

#Remove duplicated Pods. They litter the log on startup, bloat up the ipa size and lead to unpredictable bugs.
puts ""
puts "Removing duplicated Pods..."
puts ""
sharedLibrary = installer.aggregate_targets.find { |aggregate_target| aggregate_target.name == 'Pods-RestaurantSDK' }
	 installer.aggregate_targets.each do |aggregate_target|
		 atn = aggregate_target.name
		 if atn != 'Pods-RestaurantSDK'
			 puts "Checking target #{aggregate_target.name} ..."
			 aggregate_target.xcconfigs.each do |config_name, config_file|
				 puts "Checking config #{config_name} ..."
				 sharedLibraryPodTargets = sharedLibrary.pod_targets
				 aggregate_target.pod_targets.select { |pod_target| sharedLibraryPodTargets.include?(pod_target) }.each do |pod_target|
					 pod_target.specs.each do |spec|
						 frameworkPaths = unless spec.attributes_hash['ios'].nil? then spec.attributes_hash['ios']['vendored_frameworks'] else spec.attributes_hash['vendored_frameworks'] end || Set.new
						 frameworkNames = Array(frameworkPaths).map(&:to_s).map do |filename|
							 extension = File.extname filename
							 File.basename filename, extension
						 end
						 frameworkNames.each do |name|
							 puts "Removing #{name} from OTHER_LDFLAGS"
							 config_file.frameworks.delete(name)
						 end
					 end
				 end
				 xcconfig_path = aggregate_target.xcconfig_path(config_name)
				 config_file.save_as(xcconfig_path)
			 end
		 puts ""
		 end
	 end
end
