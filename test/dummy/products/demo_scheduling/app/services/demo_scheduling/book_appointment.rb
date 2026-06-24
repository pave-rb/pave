module DemoScheduling
  class BookAppointment < Pave::Service
    def call(space:, title:, scheduled_at:)
      appointment = DemoScheduling::Appointment.new(
        space: space,
        title: title,
        scheduled_at: scheduled_at
      )

      if appointment.save
        success(appointment)
      else
        failure(Pave::ValidationError.new(appointment.errors.full_messages.join(", ")))
      end
    end
  end
end
