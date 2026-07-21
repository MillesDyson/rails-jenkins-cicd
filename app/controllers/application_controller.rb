# frozen_string_literal: true

class ApplicationController < ActionController::API
  # Retorna JSON limpo (404) quando um registro não é encontrado,
  # em vez de vazar uma página de exceção do Rails.
  rescue_from ActiveRecord::RecordNotFound do |exception|
    render json: { error: exception.message }, status: :not_found
  end
end
