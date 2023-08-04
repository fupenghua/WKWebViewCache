Pod::Spec.new do |s|
  s.name             = 'WKWebViewCache'
  s.version          = '0.1.1'
  s.summary          = 'WKWebViewCache.'

  s.description      = <<-DESC
 cache for WKWebView.
                       DESC

  s.homepage         = 'https://github.com/fupenghua/WKWebViewCache'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'fupenghua' => '390908980@qq.com' }
  s.source           = { :git => 'https://github.com/fupenghua/WKWebViewCache.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'WKWebViewCache/*.{h,m}'

end
