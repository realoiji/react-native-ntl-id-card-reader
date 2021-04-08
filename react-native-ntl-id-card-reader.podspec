# react-native-ntl-id-card-reader.podspec

require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name     = "react-native-ntl-id-card-reader"
  s.version  = package['version']
  s.summary  = package['description']
  s.homepage = "https://github.com/realoiji/react-native-ntl-id-card-reader"
  s.license  = package['license']
  s.author   = package['author']
  s.source   = { :git => "https://github.com/realoiji/react-native-ntl-id-card-reader.git", :tag => "v#{s.version}" }

  s.platform = :ios, "8.0"

  s.preserve_paths = 'README.md', 'LICENSE', 'package.json', 'index.js'
  s.source_files = "ios/**/*.{h,c,cc,cpp,m,mm,swift}"

  s.dependency 'React'
end


