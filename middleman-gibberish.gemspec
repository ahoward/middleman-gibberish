## middleman-gibberish.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "middleman-gibberish"
  spec.version = "0.7.0"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "middleman-gibberish"
  spec.description = "password protect middleman pages - even on s3"
  spec.license = "same as ruby's" 

  spec.files =
["README.md",
 "Rakefile",
 "assets",
 "assets/gibberish.js",
 "assets/jquery.cookie.js",
 "assets/jquery.js",
 "lib",
 "lib/middleman-gibberish.rb",
 "middleman-gibberish.gemspec"]

  spec.executables = []
  
  spec.require_path = "lib"

  spec.test_files = nil

  
    spec.add_dependency(*["middleman", ">= 3.0"])
  
    spec.add_dependency(*["gibberish", "2.0"])
  

  spec.extensions.push(*[])

  spec.rubyforge_project = "codeforpeople"
  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "https://github.com/ahoward/middleman-gibberish"
end
