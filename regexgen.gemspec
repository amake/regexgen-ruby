# frozen_string_literal: true

require_relative 'lib/regexgen/version'

Gem::Specification.new do |spec|
  spec.name          = 'regexgen'
  spec.version       = Regexgen::VERSION
  spec.authors       = ['Aaron Madlon-Kay']
  spec.email         = ['aaron@madlon-kay.com']

  spec.summary       = 'Generate a minimal regex matching a set of strings'
  spec.homepage      = 'https://github.com/amake/regexgen-ruby'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/amake/regexgen-ruby.git'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
