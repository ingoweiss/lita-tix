Gem::Specification.new do |spec|
  spec.name          = "lita-tix"
  spec.version       = "0.3.4"
  spec.authors       = ["Ingo Weiss"]
  spec.email         = ["ingo@ingoweiss.com"]
  spec.description   = %q{Rally commands for lita, such as story/defect/task lookup}
  spec.summary       = %q{Rally commands for lita}
  spec.homepage      = "https://github.com/ingoweiss/lita-tix"
  spec.license       = "MIT"
  spec.metadata      = { "lita_plugin_type" => "handler" }

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita", "4.6.0"
  spec.add_runtime_dependency "rally_rest_api", "~> 1.1"
  spec.add_runtime_dependency "builder", "~> 3.2"
  spec.add_runtime_dependency "lita-non-command-only", "~> 0.1"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "timecop", "~> 0.7"
  spec.add_development_dependency "byebug"
end

