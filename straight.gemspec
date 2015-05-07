# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: straight 0.2.2 ruby lib

Gem::Specification.new do |s|
  s.name = "straight"
  s.version = "0.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Roman Snitko"]
  s.date = "2015-05-07"
  s.description = "An engine for the Straight payment gateway software. Requires no state to be saved (that is, no storage or DB). Its responsibilities only include processing data coming from an actual gateway."
  s.email = "roman.snitko@gmail.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = [
    ".document",
    ".rspec",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "VERSION",
    "lib/straight.rb",
    "lib/straight/blockchain_adapter.rb",
    "lib/straight/blockchain_adapters/biteasy_adapter.rb",
    "lib/straight/blockchain_adapters/blockchain_info_adapter.rb",
    "lib/straight/blockchain_adapters/mycelium_adapter.rb",
    "lib/straight/exchange_rate_adapter.rb",
    "lib/straight/exchange_rate_adapters/average_rate_adapter.rb",
    "lib/straight/exchange_rate_adapters/bitpay_adapter.rb",
    "lib/straight/exchange_rate_adapters/bitstamp_adapter.rb",
    "lib/straight/exchange_rate_adapters/btce_adapter.rb",
    "lib/straight/exchange_rate_adapters/coinbase_adapter.rb",
    "lib/straight/exchange_rate_adapters/kraken_adapter.rb",
    "lib/straight/exchange_rate_adapters/localbitcoins_adapter.rb",
    "lib/straight/exchange_rate_adapters/okcoin_adapter.rb",
    "lib/straight/gateway.rb",
    "lib/straight/order.rb",
    "spec/lib/blockchain_adapters/biteasy_adapter_spec.rb",
    "spec/lib/blockchain_adapters/blockchain_info_adapter_spec.rb",
    "spec/lib/blockchain_adapters/mycelium_adapter_spec.rb",
    "spec/lib/exchange_rate_adapter_spec.rb",
    "spec/lib/exchange_rate_adapters/average_rate_adapter_spec.rb",
    "spec/lib/exchange_rate_adapters/bitpay_adapter_spec.rb",
    "spec/lib/exchange_rate_adapters/bitstamp_adapter_spec.rb",
    "spec/lib/exchange_rate_adapters/btce_adapter_spec.rb",
    "spec/lib/exchange_rate_adapters/coinbase_adapter_spec.rb",
    "spec/lib/exchange_rate_adapters/kraken_adapter_spec.rb",
    "spec/lib/exchange_rate_adapters/localbitcoins_adapter_spec.rb",
    "spec/lib/exchange_rate_adapters/okcoin_adapter_spec.rb",
    "spec/lib/gateway_spec.rb",
    "spec/lib/order_spec.rb",
    "spec/spec_helper.rb",
    "straight.gemspec"
  ]
  s.homepage = "http://github.com/snitko/straight"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.5"
  s.summary = "An engine for the Straight payment gateway software"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<money-tree>, [">= 0"])
      s.add_runtime_dependency(%q<satoshi-unit>, [">= 0"])
      s.add_runtime_dependency(%q<httparty>, [">= 0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 2.0.1"])
      s.add_development_dependency(%q<github_api>, ["= 0.11.3"])
    else
      s.add_dependency(%q<money-tree>, [">= 0"])
      s.add_dependency(%q<satoshi-unit>, [">= 0"])
      s.add_dependency(%q<httparty>, [">= 0"])
      s.add_dependency(%q<bundler>, ["~> 1.0"])
      s.add_dependency(%q<jeweler>, ["~> 2.0.1"])
      s.add_dependency(%q<github_api>, ["= 0.11.3"])
    end
  else
    s.add_dependency(%q<money-tree>, [">= 0"])
    s.add_dependency(%q<satoshi-unit>, [">= 0"])
    s.add_dependency(%q<httparty>, [">= 0"])
    s.add_dependency(%q<bundler>, ["~> 1.0"])
    s.add_dependency(%q<jeweler>, ["~> 2.0.1"])
    s.add_dependency(%q<github_api>, ["= 0.11.3"])
  end
end

