Pod::Spec.new do |spec|
    spec.name         = 'Patch'
    spec.version      = '0.0.1'
    spec.license      = { :type => 'BSD' }
    spec.homepage     = 'https://oriente.com'
    spec.authors      = { 'wangyu' => 'yu.wang@oriente.com' }
    spec.summary      = '用于基于JScore的热修复方案'
    spec.source       = { :git => 'https://none', :tag => '0.1' }
    spec.source_files = 'Patch/**/*.{h,m}'
    spec.vendored_libraries = 'Patch/**/*.a'
    spec.requires_arc = true
  end