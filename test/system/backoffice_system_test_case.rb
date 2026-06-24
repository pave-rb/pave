# frozen_string_literal: true

require "application_system_test_case"

class BackofficeSystemTestCase < ApplicationSystemTestCase
  def sign_in_to_backoffice(user)
    visit "/admin/sign_in"
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Sign in"
    assert_current_path "/admin/"
  end
end
