Pod::Spec.new do |s|
s.name         = 'ABReviewReminder'
s.version      = '1.0'
s.summary      = "A utility that reminds your iPhone and iPad app's users to review the app."
s.description  = "ABReviewReminder is a utility written in Swift 2.0 that reminds the iPhone and iPad app users (iOS 8.0 or later) to review and rate your app."
s.homepage     = 'https://github.com/adilbenmoussa/ABReviewReminder'
s.license      = 'MIT'
s.author       = { 'Adil Ben Moussa' => 'adil.benmoussa@gmail.com' }
s.social_media_url   = 'http://twitter.com/adilbenmoussa'
s.platform     = :ios
s.ios.deployment_target = '8.0'
s.frameworks   = ['SystemConfiguration']
s.source       = { :git => 'https://github.com/adilbenmoussa/ABReviewReminder.git', :tag => "#{s.version}" }
s.source_files  = 'ABReviewReminder/*.{h,swift}'
s.resource_bundles = {'ABReviewReminder' => '**/*.lproj' }
end
