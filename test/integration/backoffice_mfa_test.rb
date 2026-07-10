# frozen_string_literal: true

require "test_helper"

class BackofficeMfaTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
  end

  test "super admin sign in is routed through engine-owned mfa setup" do
    post "/admin/sign_in", params: { email: @admin.email, password: "password123" }

    assert_redirected_to "/admin/mfa/challenge"

    get "/admin/mfa/challenge"
    assert_redirected_to "/admin/mfa/totp_enrollment/new"
  end

  test "super admin can register passkey during backoffice mfa setup" do
    post "/admin/sign_in", params: { email: @admin.email, password: "password123" }
    assert_redirected_to "/admin/mfa/challenge"

    post "/admin/mfa/passkeys/registration_options"
    assert_response :success

    options = JSON.parse(response.body)
    credential = webauthn_fake_client.create(
      challenge: options.fetch("challenge"),
      rp_id: WebAuthn.configuration.rp_id,
      user_verified: true
    )

    post "/admin/mfa/passkeys", params: {
      label: "MacBook Pro",
      public_key_credential: credential
    }, as: :json

    assert_response :success
    assert_equal "/admin/mfa/recovery_codes", JSON.parse(response.body).fetch("redirect_url")
  end
end
