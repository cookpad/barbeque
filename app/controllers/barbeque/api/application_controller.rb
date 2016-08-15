require 'garage'

class Barbeque::Api::ApplicationController < ActionController::Base
  include Garage::ControllerHelper

  rescue_from ActiveRecord::RecordNotFound do |exception|
    respond_with_error(404, 'record_not_found', exception.message)
  end

  rescue_from WeakParameters::ValidationError do |exception|
    respond_with_error(400, 'invalid_parameter', exception.message)
  end

  private

  # @param [Integer] status_code HTTP status code
  # @param [String] error_code Must be unique
  # @param [String] message Error message for API client, not for end user.
  def respond_with_error(status_code, error_code, message)
    render json: { status_code: status_code, error_code: error_code, message: message }, status: status_code
  end
end
