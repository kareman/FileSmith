Pod::Spec.new do |s|
  s.name         = 'FileSmith'
  s.version      = '0.1.5'
  s.summary      = 'A strongly typed Swift library for working with local files and directories.'
  s.description  = 'FileSmith differentiates between file paths and directory paths, and between paths and actual files and directories, because the programmer knows which are which and when the compiler knows it too it can be much more helpful.'
  s.homepage     = 'https://github.com/kareman/FileSmith'
  s.license      = { type: 'MIT', file: 'LICENSE' }
  s.author = { 'Kare Morstol' => 'kare@nottoobadsoftware.com' }
  s.source = { git: 'https://github.com/kareman/FileSmith.git', tag: s.version.to_s }
  s.source_files = 'Sources/*.swift'
  s.osx.deployment_target = '10.10'
  s.ios.deployment_target = '9.0'
  s.dependency 'SwiftShell', '= 3.0.0'
end
