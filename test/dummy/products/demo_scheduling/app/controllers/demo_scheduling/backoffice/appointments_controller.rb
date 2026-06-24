module DemoScheduling
  module Backoffice
    class AppointmentsController < Pave::Backoffice::Products::BaseController
      def index
        @appointments = DemoScheduling::Appointment.all
      end

      def show
        @appointment = DemoScheduling::Appointment.find(params[:id])
      end
    end
  end
end
