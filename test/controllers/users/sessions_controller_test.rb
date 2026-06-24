# frozen_string_literal: true

require "test_helper"

module Users
  class SessionsControllerTest < ActionDispatch::IntegrationTest
    test "sign in redirects without flash notice" do
      user = users(:manager)

      post user_session_path, params: {
        user: {
          email: user.email,
          password: "password123"
        }
      }

      assert_response :redirect
      assert_nil flash[:notice]
    end

    test "sign out redirects without flash notice" do
      sign_in users(:manager)

      delete destroy_user_session_path

      assert_response :redirect
      assert_nil flash[:notice]
    end
  end
end
