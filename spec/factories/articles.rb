# frozen_string_literal: true

FactoryBot.define do
  factory :article do
    sequence(:title) { |n| "Artigo de exemplo ##{n}" }
    body { "Conteúdo do artigo com texto suficiente para o corpo." }
    published { false }

    trait :published do
      published { true }
    end

    trait :draft do
      published { false }
    end
  end
end
