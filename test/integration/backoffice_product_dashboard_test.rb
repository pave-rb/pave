require "test_helper"

class BackofficeProductDashboardTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
  end

  def sign_in_to_backoffice
    post "/admin/sign_in", params: { email: @admin.email, password: "password123" }
    assert_redirected_to "/admin/"
  end

  test "product dashboard renders in backoffice" do
    sign_in_to_backoffice
    get "/admin/demo_scheduling"
    assert_response :success
  end

  test "product panel routes resolve for demo_scheduling" do
    sign_in_to_backoffice
    get "/admin/demo_scheduling/dashboard"
    assert_response :success
  end

  test "product appointments panel is accessible" do
    sign_in_to_backoffice
    get "/admin/demo_scheduling/appointments"
    assert_response :success
  end

  test "product spaces panel is accessible" do
    sign_in_to_backoffice
    get "/admin/demo_scheduling/spaces"
    assert_response :success
  end

  test "product users panel is accessible" do
    sign_in_to_backoffice
    get "/admin/demo_scheduling/users"
    assert_response :success
  end

  test "unknown product panel returns 404" do
    sign_in_to_backoffice
    get "/admin/demo_scheduling/nonexistent"
    assert_response :not_found
  end

  test "unknown product returns 404" do
    sign_in_to_backoffice
    get "/admin/nonexistent_product"
    assert_response :not_found
  end

  test "product dashboard requires authentication" do
    get "/admin/demo_scheduling"
    assert_redirected_to "/admin/sign_in"
  end
end
