require "rails_helper"

RSpec.describe "Courses API", type: :request do
  describe "POST /api/v1/courses" do
    let(:payload) do
      {
        course: {
          name: "Ruby on Rails",
          tutors_attributes: [
            { name: "Ada Lovelace", email: "ada@example.com" },
            { name: "Grace Hopper", email: "grace@example.com" }
          ]
        }
      }
    end

    it "creates a course and its tutors atomically" do
      expect { post "/api/v1/courses", params: payload, as: :json }
        .to change(Course, :count).by(1)
        .and change(Tutor, :count).by(2)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("name" => "Ruby on Rails")
      expect(response.parsed_body.fetch("tutors").map { |tutor| tutor.fetch("email") })
        .to contain_exactly("ada@example.com", "grace@example.com")
    end

    it "returns validation errors and does not persist a partial record" do
      payload[:course][:tutors_attributes][0][:email] = "not-an-email"

      expect { post "/api/v1/courses", params: payload, as: :json }
        .not_to change(Course, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to have_key("tutors.email")
    end

    it "normalizes tutor emails before saving" do
      payload[:course][:tutors_attributes][0][:email] = " ADA@EXAMPLE.COM "

      post "/api/v1/courses", params: payload, as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.fetch("tutors").first.fetch("email")).to eq("ada@example.com")
    end

    it "rejects duplicate tutor emails without creating the course" do
      Tutor.create!(course: Course.create!(name: "Existing"), name: "Ada", email: "ada@example.com")
      payload[:course][:tutors_attributes][0][:email] = "ADA@EXAMPLE.COM"

      course_count = Course.count
      tutor_count = Tutor.count

      post "/api/v1/courses", params: payload, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to have_key("tutors.email")
      expect(Course.count).to eq(course_count)
      expect(Tutor.count).to eq(tutor_count)
    end

    it "returns a bad request when the course wrapper is missing" do
      post "/api/v1/courses", params: {}, as: :json

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body.fetch("errors")).to have_key("course")
    end
  end

  describe "GET /api/v1/courses" do
    it "lists each course with its tutors" do
      ruby = Course.create!(name: "Ruby")
      ruby.tutors.create!(name: "Matz", email: "matz@example.com")
      Course.create!(name: "JavaScript")

      get "/api/v1/courses", as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.map { |course| course.fetch("name") }).to eq([ "Ruby", "JavaScript" ])
      expect(response.parsed_body.first.fetch("tutors")).to include(a_hash_including("name" => "Matz"))
      expect(response.parsed_body.last.fetch("tutors")).to eq([])
    end
  end
end
