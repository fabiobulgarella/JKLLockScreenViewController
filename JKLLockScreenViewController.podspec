Pod::Spec.new do |s|
  s.name         = 'JKLLockScreenViewController'
  s.version      = '1.0.1'
  s.summary      = 'It is Lock Screen Controller on platform iOS.'
  s.author = {
    'Choi Joong Kwan' => 'joongkwan.choi@gmail.com'
  }
  s.source = {
    :git => 'https://github.com/leshkoapps/JKLLockScreenViewController.git',
    :tag => s.version.to_s
  }
  s.homepage     = "http://tiny2n.tistory.com"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.platform = :ios, '9.0'
  s.source_files = 'LockScreenViewController/*.{h,m,xib}'
  s.requires_arc = true
end
