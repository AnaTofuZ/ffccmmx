# frozen_string_literal: true

require_relative "lib/ffccmmx/version"

Gem::Specification.new do |spec|
  spec.name = "ffccmmx"
  spec.version = Ffccmmx::VERSION
  spec.authors = ["anatofuz"]
  spec.email = ["anatofuz@gmail.com"]

  spec.summary = "Firebase Cloud Messaging API wrapper for ruby, supports HTTP/2 using httpx gem, based fcmpush"
  spec.description = "FCM API wrapper, supports HTTP/2 using httpx gem. This gem is based on fcmpush gem."
  spec.homepage = "https://github.com/AnaTofuZ/ffccmmx"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/AnaTofuZ/ffccmmx"
  spec.metadata["changelog_uri"] = "https://github.com/AnaTofuZ/ffccmmx/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile flake. gemset.nix])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "google-apis-identitytoolkit_v3", "~> 0.18.0"
  spec.add_dependency "httpx", "~> 1.5"

  spec.add_development_dependency "timecop", "~> 0.9"
  spec.add_development_dependency "webmock", "~> 3.25"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
