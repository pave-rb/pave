require "test_helper"

class BackofficeProductPanelsTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
  end

  def sign_in_to_backoffice
    post "/admin/sign_in", params: { email: @admin.email, password: "password123" }
    assert_redirected_to "/admin/"
  end

  test "demo_scheduling is registered as a product" do
    assert_includes Pave.products.keys, :demo_scheduling
  end

  test "demo_scheduling has backoffice panels registered" do
    panels = Pave::Backoffice.registry.product_panels(:demo_scheduling)
    panel_names = panels.map(&:name)

    assert_includes panel_names, :dashboard
    assert_includes panel_names, :appointments
    assert_includes panel_names, :spaces
    assert_includes panel_names, :users
  end

  test "demo_scheduling dashboard controller exists" do
    assert Pave::Backoffice::RouteDrawer.controller_available?("demo_scheduling/backoffice/dashboard")
  end

  test "demo_scheduling appointments controller exists" do
    assert Pave::Backoffice::RouteDrawer.controller_available?("demo_scheduling/backoffice/appointments")
  end

  test "demo_scheduling spaces controller exists" do
    assert Pave::Backoffice::RouteDrawer.controller_available?("demo_scheduling/backoffice/spaces")
  end

  test "demo_scheduling users controller exists" do
    assert Pave::Backoffice::RouteDrawer.controller_available?("demo_scheduling/backoffice/users")
  end

  test "product backoffice engine mounts at /admin" do
    sign_in_to_backoffice
    get "/admin/demo_scheduling"
    assert_response :success
  end

  test "product backoffice panels are ordered by position" do
    panels = Pave::Backoffice.registry.product_panels(:demo_scheduling)
    positions = panels.map(&:position)

    assert_equal positions.sort, positions,
      "Expected panels to be ordered by position"
  end
end
