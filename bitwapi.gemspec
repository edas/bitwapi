
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "bitwapi/version"

Gem::Specification.new do |spec|
  spec.name          = "bitwapi"
  spec.version       = Bitwapi::VERSION
  spec.authors       = ["Éric D."]
  spec.email         = ["15271+edas@users.noreply.github.com"]
  spec.license       = 'ISC' # https://spdx.org/licenses/ISC.html
  spec.summary       = "Unofficial Bitwarden API client"
  spec.description   = "Unofficial ruby client for the Bitwarden API. With it you can retrieve your vault, send your modifications, get new modifications from the server and access the content."
  spec.homepage      = "https://github.com/edas/biwapi"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rest-client", "~> 2.1.0.rc1"
  spec.add_dependency "pbkdf2-ruby"
  spec.add_dependency "jwt", '~> 1.5', '>= 1.5.4'

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
