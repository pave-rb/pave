module DemoScheduling
  class Appointment < ApplicationRecord
    belongs_to :space, class_name: "Pave::Tenancy::Space", optional: true

    validates :title, presence: true
    validates :scheduled_at, presence: true
  end
end
