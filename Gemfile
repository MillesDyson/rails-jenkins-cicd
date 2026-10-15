# frozen_string_literal: true

source "https://rubygems.org"

gem "rails", "~> 8.0"
# Banco de dados
gem "pg", "~> 1.1"
# Servidor de aplicação
gem "puma", ">= 5.0"
# CORS para permitir chamadas cross-origin à API
gem "rack-cors"

# Windows não inclui zoneinfo; empacota tzinfo-data quando necessário
gem "tzinfo-data", platforms: %i[windows jruby]

# Reduz o tempo de boot via cache; requerido em config/boot.rb
gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"

  # Framework de testes
  gem "rspec-rails", "~> 7.1"
  # Fábricas de dados de teste
  gem "factory_bot_rails"
  # Matchers expressivos para models/requests
  gem "shoulda-matchers", "~> 8.0"
end

group :development do
  # Análise estática de segurança (SAST)
  gem "brakeman", require: false
  # Auditoria de vulnerabilidades conhecidas nas dependências
  gem "bundler-audit", require: false
  # Linter / style guide
  gem "rubocop", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
end

group :test do
  # Relatório de cobertura de testes
  gem "simplecov", require: false
  # Gera relatório JUnit XML para o Jenkins publicar os resultados dos testes
  gem "rspec_junit_formatter", require: false
end
