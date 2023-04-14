Pod::Spec.new do |s|
  s.name             = 'SmallEye'
  s.version          = '0.1'
  s.summary          = 'SmallEye'
  s.description      = "磁盘浏览器"
  s.homepage         = 'https://github.com/NSSONGMENG/SmallEyes.git'
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = { 'song.meng' => '740621245@qq.com' }
  s.source           = { :git => 'https://github.com/NSSONGMENG/SmallEyes.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.prefix_header_file = false
  s.resources = 'SmallEye/resource/*'

  s.source_files = 'SmallEye/*.{h,m}'
  s.frameworks  = 'UIKit', 'Foundation'
end
