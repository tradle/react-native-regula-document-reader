
Pod::Spec.new do |s|
  s.name         = "RNRegulaDocumentReader"
  s.version      = "1.0.0"
  s.summary      = "RNRegulaDocumentReader"
  s.description  = <<-DESC
                  RNRegulaDocumentReader
                   DESC
  s.homepage     = ""
  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "author" => "author@domain.cn" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/author/RNRegulaDocumentReader.git", :tag => "master" }
  s.source_files  = "RNRegulaDocumentReader/**/*.{h,m}"
  s.requires_arc = true


  s.dependency "React"
  s.dependency "DocumentReader"
  s.dependency "DocumentReaderFull"

end


