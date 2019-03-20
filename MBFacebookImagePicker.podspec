#
# Be sure to run `pod lib lint MBFacebookImagePicker.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MBFacebookImagePicker'
  s.version          = '1.0.5'
  s.summary          = 'A simple image picker for Facebook written in Swift.'

  s.homepage         = 'https://github.com/mikaelbo/MBFacebookImagePicker'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'mikaelbo' => 'mbo@mbo42.com' }
  s.source           = { :git => 'https://github.com/mikaelbo/MBFacebookImagePicker.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'MBFacebookImagePicker/**/*'
  
  s.dependency 'FBSDKCoreKit', '~> 4.41.2'
  s.dependency 'FBSDKLoginKit', '~> 4.41.2'

end
