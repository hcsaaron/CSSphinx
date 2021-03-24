Pod::Spec.new do |s|
  s.name         = "CSSphinx"
  s.version      = "0.0.1"
  s.summary      = "基于Pocketsphinx的本地语音识别、语音唤醒"
  s.description  = <<-DESC
	CMUSphinx官方语言模型识别效果非常差，需要自己训练语言模型和调整（训练）声学模型
                   DESC
  s.platform     = :ios, "9.0"
  s.license      = "MIT"
  s.homepage     = "https://github.com/hcsaaron/CSSphinx"
  s.author       = { "Aaron" => "hcsaaron@163.com" }

  s.source       = { :git => "https://github.com/hcsaaron/CSSphinx.git", :tag => s.version }
  s.source_files = "CSSphinx/**/*.{h,m}"
  s.resources 	 = 'CSSphinx/Sphinx/**/*'

  s.vendored_libraries = 'CSSphinx/lib/**/*.a'
end