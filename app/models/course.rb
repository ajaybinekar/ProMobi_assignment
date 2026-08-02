class Course < ApplicationRecord
  has_many :tutors, dependent: :restrict_with_exception, inverse_of: :course

  accepts_nested_attributes_for :tutors

  validates :name, presence: true
end
