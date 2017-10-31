
Pod::Spec.new do |s|
  s.name             = 'YLT_SIP'
  s.version          = '0.0.1'
  s.summary          = 'A short description of YLT_SIP.'


  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/YLTTeam/YLT_SIP'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'xphaijj' => 'xphaijj0305@126.com' }
  s.source           = { :git => 'https://github.com/YLTTeam/YLT_SIP.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'YLT_SIP/Classes/**/*'
  
  s.dependency 'YLT_PJSip'
  s.dependency 'YLT_BaseLib'
  s.dependency 'OpenSSL'
  s.dependency 'ReactiveObjC'

end
