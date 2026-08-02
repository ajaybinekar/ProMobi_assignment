module Api
  module V1
    class CoursesController < BaseController
      def index
        courses = Course.includes(:tutors).order(:id)
        render json: courses.as_json(include: { tutors: { only: %i[id name email] } }, only: %i[id name created_at updated_at])
      end

      def create
        course = Course.new(course_params)

        if course.save
          render json: course.as_json(include: { tutors: { only: %i[id name email] } }, only: %i[id name created_at updated_at]), status: :created
        else
          render_validation_errors(course)
        end
      end

      private

      def course_params
        params.require(:course).permit(:name, tutors_attributes: %i[name email])
      end
    end
  end
end
