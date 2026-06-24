require "test_helper"

module DemoScheduling
  module Backoffice
    class AppointmentsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @admin = users(:admin)
      end

      def sign_in_to_backoffice
        post "/admin/sign_in", params: { email: @admin.email, password: "password123" }
        assert_redirected_to "/admin/"
      end

      test "appointments index requires authentication" do
        get "/admin/demo_scheduling/appointments"
        assert_redirected_to "/admin/sign_in"
      end

      test "appointments index renders for authenticated admin" do
        sign_in_to_backoffice
        get "/admin/demo_scheduling/appointments"
        assert_response :success
      end
    end
  end
end
