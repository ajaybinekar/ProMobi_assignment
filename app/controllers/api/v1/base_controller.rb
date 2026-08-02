module Api
  module V1
    class BaseController < ActionController::API
      rescue_from ActionController::ParameterMissing, with: :render_bad_request
      rescue_from ActiveRecord::RecordNotUnique, with: :render_conflict

      private

      def render_validation_errors(record)
        render json: { errors: record.errors.to_hash(true) }, status: :unprocessable_content
      end

      def render_bad_request(error)
        render json: { errors: { error.param => [ error.message ] } }, status: :bad_request
      end

      def render_conflict(_error)
        render json: { errors: { email: [ "has already been taken" ] } }, status: :conflict
      end
    end
  end
end
