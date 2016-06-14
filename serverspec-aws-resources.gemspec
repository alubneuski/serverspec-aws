Gem::Specification.new do |s|
  s.name        = 'serverspec-aws-resources'
  s.version     = '0.0.8'
  s.date        = '2016-01-12'
  s.summary     = 'serverspec resource types to test AWS resources'
  s.description = s.summary
  s.authors     = %w{Eric Kascic, Alex Lubneuski}
  s.email       = 'eric.kascic@stelligent.com alex.lubneuski@gmail.com'
  s.files       =  Dir['lib/*.rb'] + Dir['lib/resources/*.rb']

  s.add_runtime_dependency 'aws-sdk', '>= 2.0.0'
end
