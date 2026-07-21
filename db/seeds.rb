# frozen_string_literal: true

# Dados de exemplo para o ambiente de desenvolvimento/demonstração.
# Idempotente: pode ser executado várias vezes com `bin/rails db:seed`.

articles = [
  {
    title: "Introdução ao CI/CD com Jenkins",
    body: "Pipeline como código com Jenkinsfile declarativo.",
    published: true
  },
  {
    title: "Dockerizando uma aplicação Rails",
    body: "Build multi-stage e imagem enxuta para produção.",
    published: true
  },
  {
    title: "Testes com RSpec",
    body: "Model specs e request specs com FactoryBot.",
    published: true
  },
  {
    title: "Rascunho: próximos passos",
    body: "Ideias ainda não publicadas.",
    published: false
  }
]

articles.each do |attrs|
  Article.find_or_create_by!(title: attrs[:title]) do |article|
    article.body = attrs[:body]
    article.published = attrs[:published]
  end
end

Rails.logger.info("Seed concluído: #{Article.count} artigos no banco.")
