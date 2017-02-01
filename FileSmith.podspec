Pod::Spec.new do |s|
  s.name         = 'FileSmith'
  s.version      = '0.1.0-alpha.5'
  s.summary      = 'A strongly typed Swift library for working with local files and directories.'
  s.description  = 'A strongly typed Swift library for working with local files and directories.'
  s.homepage     = 'https://github.com/kareman/FileSmith'
  s.license      = { type: 'MIT', file: 'LICENSE' }
  s.author = { 'Kare Morstol' => 'kare@nottoobadsoftware.com' }
  s.source = { git: 'https://github.com/kareman/FileSmith.git', tag: s.version.to_s }
  s.source_files = 'Sources/*.swift'
  s.osx.deployment_target = '10.10'
end
