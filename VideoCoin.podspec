Pod::Spec.new do |spec|
  spec.name          = "VideoCoin"
  spec.version       = "0.0.1"
  spec.summary       = "Video Coin Network framework for iOS"
  spec.homepage      = "https://www.videocoin.io/"
  spec.license       = "MIT"
  spec.author        = { "Ryoichiro Oka" => "ryo@liveplanet.net" }
  spec.source        = { :git => "https://github.com/videocoin/orbital-app-ios.git", :tag => "#{spec.version}" }
  spec.source_files  = "VideoCoin/Classes", "VideoCoin/Classes/**/*.{h,m,swift}"
  spec.module_name   = 'VideoCoin'
  spec.swift_version = '5.0'
  spec.ios.deployment_target = '13.0'

  spec.dependency 'Alamofire', '~> 4.8'
  spec.dependency 'AlamofireImage', '~> 3.5'
  spec.dependency 'PromiseKit', '~> 6.8'
  spec.dependency 'PromiseKit/Alamofire', '~> 6.0'
  spec.dependency 'SwiftyJSON', '~> 4.0'
end
