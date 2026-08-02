class Tutor < ApplicationRecord
  belongs_to :course, inverse_of: :tutors

  validates :name, :email, presence: true
  validates :email, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }

  before_validation :normalize_email

  private

  def normalize_email
    self.email = email&.strip&.downcase
  end
end
