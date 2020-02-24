# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

def pods_Haishin
  pod 'HaishinKit', '~> 1.0.0'
end

target 'VideoCoin' do
  pod 'Alamofire', '~> 4.8'
  pod 'AlamofireImage', '~> 3.5'
  pod 'PromiseKit', '~> 6.8'
  pod 'PromiseKit/Alamofire', '~> 6.0'
end

target 'VideoCoinHost' do
  pod 'VideoCoin', :path => '.'
  pods_Haishin

  target 'VideoCoinTest' do
    inherit! :search_paths
  end
end

target 'OrbitalApp' do
  pod 'VideoCoin', :path => '.'
  pod 'GoogleSignIn'
  pod 'Firebase/Analytics'
  pod 'Firebase/Firestore'
  pod 'Firebase/Auth'
  pod 'Firebase/RemoteConfig'
  pod 'Firebase/Storage'
  pod 'Kingfisher', '~> 5.0'
  pod 'Keyboard+LayoutGuide'

  pods_Haishin

  target 'OrbitalAppTests' do
    inherit! :search_paths
  end
end


target 'RtmpDebug' do
  pods_Haishin
end
