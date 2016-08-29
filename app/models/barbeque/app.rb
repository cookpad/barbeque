class Barbeque::App < Barbeque::ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :docker_image, presence: true

  attr_readonly :name

  has_many :job_definitions
end
