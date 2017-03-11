Gem::Specification.new do |s|
  s.name        = 'cerulean'
  s.version     = '0.11.0'
  s.date        = '2016-07-27'
  s.summary     = "Cerulean"
  s.description = "API DSL."
  s.authors     = ["Kyle Kestell"]
  s.email       = 'kyle@kestell.org'
  s.files       = Dir['lib/**/*']
  s.homepage    = 'https://github.com/kkestell/cerulean'
  s.license     = 'MIT'
  s.required_ruby_version = '>= 2.0.0'
  s.add_runtime_dependency('boolean')
end
