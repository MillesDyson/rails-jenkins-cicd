# frozen_string_literal: true

require "rails_helper"

RSpec.describe Article, type: :model do
  describe "validações" do
    subject { build(:article) }

    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:title).is_at_least(3).is_at_most(200) }
  end

  describe "valores padrão" do
    it "cria um artigo como rascunho por padrão" do
      article = described_class.create!(title: "Título válido", body: "Corpo")
      expect(article.published).to be(false)
    end
  end

  describe "scopes" do
    let!(:published_article) { create(:article, :published) }
    let!(:draft_article)     { create(:article, :draft) }

    it ".published retorna apenas artigos publicados" do
      expect(described_class.published).to contain_exactly(published_article)
    end

    it ".drafts retorna apenas rascunhos" do
      expect(described_class.drafts).to contain_exactly(draft_article)
    end
  end

  describe "#published?" do
    it "é verdadeiro quando publicado" do
      expect(build(:article, :published).published?).to be(true)
    end

    it "é falso quando rascunho" do
      expect(build(:article, :draft).published?).to be(false)
    end
  end
end
