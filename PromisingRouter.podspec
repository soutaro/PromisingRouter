Pod::Spec.new do |spec|
  spec.name         = 'PromisingRouter'
  spec.version      = '1.0.0'
  spec.license      = { :type => 'MIT' }
  spec.homepage     = 'https://github.com/soutaro/PromisingRouter'
  spec.authors      = { 'Soutaro Matsumoto' => 'soutaro@ubiregi.com' }
  spec.summary      = 'Queueing URL routing library for iOS apps'
  spec.source       = { :git => 'https://github.com/ubiregiinc/PromisingRouter.git', :tag => spec.version.to_s }
  spec.source_files = 'PromisingRouter/*.swift'
  spec.platform     = :ios, "8.0"
  spec.requires_arc = true
end
