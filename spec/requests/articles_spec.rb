# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Articles API", type: :request do
  let(:valid_attributes)   { { title: "Meu primeiro artigo", body: "Conteúdo do corpo", published: true } }
  let(:invalid_attributes) { { title: "", body: "" } }

  describe "GET /articles" do
    it "retorna todos os artigos com status 200" do
      create_list(:article, 3)

      get "/articles"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(3)
    end
  end

  describe "GET /articles/:id" do
    it "retorna o artigo solicitado" do
      article = create(:article)

      get "/articles/#{article.id}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["id"]).to eq(article.id)
    end

    it "retorna 404 quando o artigo não existe" do
      get "/articles/999999"

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to have_key("error")
    end
  end

  describe "POST /articles" do
    context "com parâmetros válidos" do
      it "cria um novo artigo" do
        expect do
          post "/articles", params: { article: valid_attributes }
        end.to change(Article, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["title"]).to eq("Meu primeiro artigo")
      end
    end

    context "com parâmetros inválidos" do
      it "não cria o artigo e retorna 422" do
        expect do
          post "/articles", params: { article: invalid_attributes }
        end.not_to change(Article, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH /articles/:id" do
    let(:article) { create(:article, title: "Título antigo") }

    context "com parâmetros válidos" do
      it "atualiza o artigo" do
        patch "/articles/#{article.id}", params: { article: { title: "Título novo" } }

        expect(response).to have_http_status(:ok)
        expect(article.reload.title).to eq("Título novo")
      end
    end

    context "com parâmetros inválidos" do
      it "não atualiza e retorna 422" do
        patch "/articles/#{article.id}", params: { article: { title: "" } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(article.reload.title).to eq("Título antigo")
      end
    end
  end

  describe "DELETE /articles/:id" do
    it "remove o artigo" do
      article = create(:article)

      expect do
        delete "/articles/#{article.id}"
      end.to change(Article, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
