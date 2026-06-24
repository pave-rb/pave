require "test_helper"

module DemoScheduling
  module Backoffice
    class DashboardControllerTest < ActionDispatch::IntegrationTest
      setup do
        @admin = users(:admin)
      end

      def sign_in_to_backoffice
        post "/admin/sign_in", params: { email: @admin.email, password: "password123" }
        assert_redirected_to "/admin/"
      end

      test "dashboard index requires authentication" do
        get "/admin/demo_scheduling/dashboard"
        assert_redirected_to "/admin/sign_in"
      end

      test "dashboard index renders for authenticated admin" do
        sign_in_to_backoffice
        get "/admin/demo_scheduling/dashboard"
        assert_response :success
      end
    end
  end
end
