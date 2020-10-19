Pod::Spec.new do |s|

  s.name                = "FloatingPanel"
  s.version             = "2.0.1"
  s.summary             = "FloatingPanel is a clean and easy-to-use UI component of a floating panel interface."
  s.description         = <<-DESC
FloatingPanel is a clean and easy-to-use UI component for a new interface introduced in Apple Maps, Shortcuts and Stocks app.
The new interface displays the related contents and utilities in parallel as a user wants.
                   DESC
  s.homepage            = "https://github.com/SCENEE/FloatingPanel"
  s.author              = "Shin Yamamoto"
  s.social_media_url    = "https://twitter.com/scenee"

  s.platform            = :ios, "10.0"
  s.source              = { :git => "https://github.com/SCENEE/FloatingPanel.git", :tag => s.version.to_s }
  s.source_files        = "Sources/*.swift"
  s.swift_versions      = ['5.1', '5.2', '5.3']

  s.framework           = "UIKit"

  s.license             = { :type => "MIT", :file => "LICENSE" }
end
