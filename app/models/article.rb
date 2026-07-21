# frozen_string_literal: true

class Article < ApplicationRecord
  validates :title, presence: true, length: { minimum: 3, maximum: 200 }
  validates :body, presence: true

  scope :published, -> { where(published: true) }
  scope :drafts, -> { where(published: false) }

  def published?
    published
  end
end
