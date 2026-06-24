# frozen_string_literal: true

require "test_helper"

class PaveBackofficeContractsTest < ActiveSupport::TestCase
  # --- New context-aware registry API tests ---

  test "registry accepts platform panels" do
    registry = Pave::Backoffice::Registry.new

    registry.register_platform_panel(:users,
      label: "Users",
      controller: "pave/identity/backoffice/users",
      source: :runtime_module,
      source_package: "pave-identity",
      position: 10
    )

    assert_equal 1, registry.platform_panels.size
    assert_equal :users, registry.platform_panels.first.name
    assert_equal "users", registry.platform_panels.first.slug
    assert_equal "Users", registry.platform_panels.first.label
  end

  test "registry accepts product panels" do
    registry = Pave::Backoffice::Registry.new

    registry.register_product_panel(:demo, :spaces,
      label: "Spaces",
      controller: "demo/backoffice/spaces",
      source: :product,
      source_package: "products/demo",
      position: 20
    )

    assert_equal 1, registry.product_panels(:demo).size
    assert_equal :spaces, registry.product_panels(:demo).first.name
    assert_equal "spaces", registry.product_panels(:demo).first.slug
  end

  test "registry rejects duplicate slugs within platform context" do
    registry = Pave::Backoffice::Registry.new

    registry.register_platform_panel(:users,
      label: "Users",
      controller: "pave/identity/backoffice/users"
    )

    assert_raises(ArgumentError) do
      registry.register_platform_panel(:users,
        label: "Users Duplicate",
        controller: "pave/identity/backoffice/users"
      )
    end
  end

  test "registry rejects duplicate slugs within same product context" do
    registry = Pave::Backoffice::Registry.new

    registry.register_product_panel(:demo, :spaces,
      label: "Spaces",
      controller: "demo/backoffice/spaces"
    )

    assert_raises(ArgumentError) do
      registry.register_product_panel(:demo, :spaces,
        label: "Spaces Duplicate",
        controller: "demo/backoffice/spaces"
      )
    end
  end

  test "registry allows same slug across platform and product contexts" do
    registry = Pave::Backoffice::Registry.new

    registry.register_platform_panel(:users,
      label: "Users",
      controller: "pave/identity/backoffice/users"
    )

    registry.register_product_panel(:demo, :users,
      label: "Product Users",
      controller: "demo/backoffice/users"
    )

    assert_equal 1, registry.platform_panels.size
    assert_equal 1, registry.product_panels(:demo).size
  end

  test "panels are ordered by position then label then slug" do
    registry = Pave::Backoffice::Registry.new

    registry.register_platform_panel(:reports,
      label: "Reports", controller: "reports", position: 20
    )
    registry.register_platform_panel(:home,
      label: "Home", controller: "home", position: 10
    )
    registry.register_platform_panel(:users,
      label: "Users", controller: "users", position: 10
    )

    assert_equal %i[home users reports], registry.platform_panels.map(&:name)
  end

  test "Pave::Backoffice.platform_panel delegates to registry" do
    Pave::Backoffice.platform_panel(:test_panel,
      label: "Test Panel",
      controller: "test/controller"
    )

    assert Pave::Backoffice.panels.any? { |p| p.name == :test_panel }
  ensure
    registry = Pave::Backoffice.registry
    registry.instance_variable_get(:@platform_panels).reject! { |p| p.name == :test_panel }
  end

  test "Pave::Backoffice.product registers product panels via builder" do
    Pave::Backoffice.product(:test_product) do |b|
      b.panel :widgets,
        label: "Widgets",
        controller: "test_product/backoffice/widgets",
        position: 10
    end

    panels = Pave::Backoffice.registry.product_panels(:test_product)
    assert_equal 1, panels.size
    assert_equal :widgets, panels.first.name
  ensure
    registry = Pave::Backoffice.registry
    registry.instance_variable_get(:@product_panels).delete(:test_product)
  end

  test "Pave::Backoffice.product_panel registers plugin panel declarations" do
    Pave::Backoffice.product_panel(:test_product, :whatsapp,
      label: "WhatsApp",
      controller: "pave/plugins/whatsapp_channel/backoffice",
      source: :plugin,
      source_package: "whatsapp_channel"
    )

    panel = Pave::Backoffice.registry.product_panels(:test_product).first
    assert_equal :whatsapp, panel.name
    assert_equal :plugin, panel.source
    assert_equal "whatsapp_channel", panel.source_package
  ensure
    Pave::Backoffice.registry.instance_variable_get(:@product_panels).delete(:test_product)
  end

  test "registry product_panel hook delegates to product panel registration" do
    registry = Pave::Backoffice::Registry.new

    registry.product_panel(:demo, :whatsapp,
      label: "WhatsApp",
      source: :plugin,
      source_package: "whatsapp_channel"
    )

    assert_equal [ :whatsapp ], registry.product_panels(:demo).map(&:name)
  end

  test "panel slug is dasherized name" do
    panel = Pave::Backoffice::Panel.new(name: :audit_logs, label: "Audit Logs")
    assert_equal "audit-logs", panel.slug
  end

  test "panel with route_block stores the block" do
    block = -> { resources :items }
    panel = Pave::Backoffice::Panel.new(name: :items, label: "Items", route_block: block)
    assert_equal block, panel.route_block
  end

  # --- Deprecated flat panel API backward compat tests ---

  test "deprecated register_panel with flat key still works" do
    registry = Pave::Backoffice::Registry.new

    registry.register_panel(:dashboard, title: "Dashboard", owner: :runtime, route: :backoffice_root)

    assert_equal 1, registry.panels.size
    assert_equal :dashboard, registry.panels.first.name
  end

  test "deprecated register_panel with dotted key creates product panel" do
    registry = Pave::Backoffice::Registry.new

    registry.register_panel("demo.home", title: "Demo Home", owner: :demo, route: :backoffice_demo)

    assert_equal 1, registry.product_panels(:demo).size
    assert_equal :home, registry.product_panels(:demo).first.name
  end

  test "deprecated panels method returns combined platform and product panels" do
    registry = Pave::Backoffice::Registry.new

    registry.register_platform_panel(:users, label: "Users", controller: "users")
    registry.register_product_panel(:demo, :spaces, label: "Spaces", controller: "spaces")

    assert_equal 2, registry.panels.size
  end

  test "deprecated panel lookup by key" do
    registry = Pave::Backoffice::Registry.new

    registry.register_platform_panel(:users, label: "Users", controller: "users")

    assert_equal :users, registry.panel(:users).name
    assert_nil registry.panel(:nonexistent)
  end

  # --- Navigation tests ---

  test "navigation filters panels through authorization callback" do
    panels = [
      Pave::Backoffice::Panel.new(name: :allowed, label: "Allowed"),
      Pave::Backoffice::Panel.new(name: :denied, label: "Denied")
    ]

    navigation = Pave::Backoffice::Navigation.new(
      panels: panels,
      authorizer: ->(panel) { panel.name == :allowed }
    )

    assert_equal [ :allowed ], navigation.panels.map(&:key)
  end

  test "navigation grouped tolerates panels without group" do
    panels = [
      Pave::Backoffice::Panel.new(name: :a, label: "A"),
      Pave::Backoffice::Panel.new(name: :b, label: "B")
    ]

    navigation = Pave::Backoffice::Navigation.new(panels: panels)
    groups = navigation.grouped

    assert_equal [ :default ], groups.keys
    assert_equal 2, groups[:default].size
  end

  test "breadcrumbs expose ordered crumb contract" do
    breadcrumbs = Pave::Backoffice::Breadcrumbs.new

    breadcrumbs.add("Root", route: "/backoffice")
    breadcrumbs.add("Current")

    assert_equal [ "Root", "Current" ], breadcrumbs.map(&:title)
    assert_equal "/backoffice", breadcrumbs.first.route
  end

  test "legacy base controller inherits runtime base controller" do
    assert_operator Backoffice::BaseController, :<, Pave::Backoffice::BaseController
  end

  test "generic product panel controller inherits product base controller" do
    assert_operator Pave::Backoffice::Products::PanelsController,
      :<,
      Pave::Backoffice::Products::BaseController
  end

  test "unavailable product panel controller inherits product base controller" do
    assert_operator Pave::Backoffice::Products::UnavailableController,
      :<,
      Pave::Backoffice::Products::BaseController
  end

  test "product panels from dotted-key registration are properly categorized" do
    registry = Pave::Backoffice::Registry.new

    registry.register_panel("demo.home", title: "Demo Home", owner: :demo, route: :backoffice_demo)

    panels = registry.product_panels(:demo)
    assert_equal 1, panels.size
    assert_equal :home, panels.first.name
    assert_equal :demo, panels.first.source
  end

  test "ProductConfigLoader loads product-owned backoffice config when present" do
    product_key = :test_config_product
    root = Rails.root.join("tmp/test-products/test_config_product")
    config_path = root.join("config/backoffice.rb")

    FileUtils.mkdir_p(config_path.dirname)
    config_path.write <<~RUBY
      Pave::Backoffice.product(:test_config_product) do |backoffice|
        backoffice.panel :widgets,
          label: "Widgets",
          source: :product,
          source_package: "tmp/test-products/test_config_product"
      end
    RUBY

    begin
      product = Pave::Product.new(key: product_key, label: "Test Config Product", root: root)

      assert Pave::Backoffice::ProductConfigLoader.load_product(product)

      panels = Pave::Backoffice.registry.product_panels(product_key)
      assert_equal [ :widgets ], panels.map(&:name)
      assert_equal "tmp/test-products/test_config_product", panels.first.source_package
    ensure
      Pave::Backoffice.registry.instance_variable_get(:@product_panels).delete(product_key)
      FileUtils.rm_rf(root)
    end
  end

  test "ProductConfigLoader treats missing product backoffice config as valid" do
    product = Pave::Product.new(
      key: :test_missing_config_product,
      label: "Test Missing Config Product",
      root: Rails.root.join("tmp/test-products/test_missing_config_product")
    )

    refute Pave::Backoffice::ProductConfigLoader.load_product(product)
  end

  # --- Reserved name validation tests ---

  test "ReservedNameError defines reserved slugs" do
    assert_includes Pave::Backoffice::ReservedNameError::RESERVED_SLUGS, "users"
    assert_includes Pave::Backoffice::ReservedNameError::RESERVED_SLUGS, "audit"
    assert_includes Pave::Backoffice::ReservedNameError::RESERVED_SLUGS, "settings"
    assert_includes Pave::Backoffice::ReservedNameError::RESERVED_SLUGS, "credentials"
    assert_includes Pave::Backoffice::ReservedNameError::RESERVED_SLUGS, "health"
    assert_includes Pave::Backoffice::ReservedNameError::RESERVED_SLUGS, "platform"
  end

  test "ReservedNameError includes slug in message" do
    error = Pave::Backoffice::ReservedNameError.new("users")
    assert_match(/users/, error.message)
    assert_match(/reserved/, error.message)
  end

  # --- Route drawer tests ---

  test "RouteDrawer controller_available? returns true for existing controller" do
    assert Pave::Backoffice::RouteDrawer.controller_available?("pave/backoffice/base_controller")
  end

  test "RouteDrawer controller_available? returns false for missing controller" do
    refute Pave::Backoffice::RouteDrawer.controller_available?("pave/backoffice/nonexistent_controller")
  end

  test "RouteDrawer FALLBACK_CONTROLLER constant points to unavailable controller" do
    assert_equal "pave/backoffice/products/unavailable", Pave::Backoffice::RouteDrawer::FALLBACK_CONTROLLER
  end

  test "RouteDrawer GENERIC_CONTROLLER constant points to product panels controller" do
    assert_equal "pave/backoffice/products/panels", Pave::Backoffice::RouteDrawer::GENERIC_CONTROLLER
  end

  test "RouteDrawer unknown controller routes to fallback" do
    panel = Pave::Backoffice::Panel.new(
      name: :missing_panel,
      label: "Missing Panel",
      controller: "pave/backoffice/products/missing_controller"
    )

    calls = []
    router = Object.new
    router.define_singleton_method(:get) { |*args| calls << args }

    Pave::Backoffice::RouteDrawer.draw_panel_route(router, "test_product", panel)

    route_call = calls.find { |path, _| path == "/missing-panel" }
    assert route_call, "Expected a route call for /missing-panel"
    assert_equal "products/unavailable#index", route_call[1][:to]
  end

  test "RouteDrawer panel without controller routes to generic overview" do
    panel = Pave::Backoffice::Panel.new(
      name: :metadata_panel,
      label: "Metadata Panel"
    )

    calls = []
    router = Object.new
    router.define_singleton_method(:get) { |*args| calls << args }

    Pave::Backoffice::RouteDrawer.draw_panel_route(router, "test_product", panel)

    route_call = calls.find { |path, _| path == "/metadata-panel" }
    assert route_call, "Expected a route call for /metadata-panel"
    assert_equal "products/panels#index", route_call[1][:to]
    assert_equal "metadata-panel", route_call[1][:defaults][:panel_id]
  end

  test "RouteDrawer known controller routes to its own controller" do
    panel = Pave::Backoffice::Panel.new(
      name: :base_controller,
      label: "Base Controller",
      controller: "pave/backoffice/base_controller"
    )

    calls = []
    router = Object.new
    router.define_singleton_method(:get) { |*args| calls << args }

    Pave::Backoffice::RouteDrawer.draw_panel_route(router, "test_product", panel)

    route_call = calls.find { |path, _| path == "/base-controller" }
    assert route_call, "Expected a route call for /base-controller"
    assert_equal "base_controller#index", route_call[1][:to]
  end

  test "RouteDrawer panel with route_block yields to block" do
    captured = nil
    block = -> { captured = :block_executed }

    panel = Pave::Backoffice::Panel.new(
      name: :block_panel,
      label: "Block Panel",
      controller: "pave/backoffice/base_controller",
      route_block: block
    )

    router = Object.new
    def router.scope(...)
      yield
    end

    Pave::Backoffice::RouteDrawer.draw_panel_route(router, "test_product", panel)
    assert_equal :block_executed, captured
  end

  test "RouteDrawer.validate_panel_controllers! returns hash with missing_controllers key" do
    result = Pave::Backoffice::RouteDrawer.validate_panel_controllers!

    assert_kind_of Hash, result
    assert result.key?(:missing_controllers)
    assert_kind_of Array, result[:missing_controllers]
  end

  test "RouteDrawer.validate_panel_controllers! finds missing controllers when registered" do
    existing_product = Pave.products.first
    skip "No products registered for testing" unless existing_product

    registry = Pave::Backoffice.registry
    registry.register_product_panel(existing_product.key, :missing_controller_panel,
      label: "Missing Controller",
      controller: "pave/backoffice/nonexistent/controller"
    )

    result = Pave::Backoffice::RouteDrawer.validate_panel_controllers!

    assert_operator result[:missing_controllers].length, :>=, 1
    assert_includes result[:missing_controllers].map { |d| d[:controller] },
                    "pave/backoffice/nonexistent/controller"
  ensure
    if existing_product
      panels = registry.instance_variable_get(:@product_panels)[existing_product.key]
      panels&.reject! { |p| p.name == :missing_controller_panel }
    end
  end

  # --- Product validator tests ---

  test "ProductValidator#validate! does not raise when no reserved names exist" do
    Pave::Backoffice::ProductValidator.validate!
    assert true
  end

  test "ProductValidator RESERVED_SLUGS matches ReservedNameError" do
    assert_equal Pave::Backoffice::ReservedNameError::RESERVED_SLUGS,
                 Pave::Backoffice::ProductValidator::RESERVED_SLUGS
  end

  test "ProductValidator.validate! raises ReservedNameError for reserved product key" do
    product_key = :platform

    begin
      Pave.product(product_key, label: "Test Reserved", root: Rails.root.join("tmp"))

      assert_raises(Pave::Backoffice::ReservedNameError) do
        Pave::Backoffice::ProductValidator.validate!
      end
    ensure
      Pave.products.instance_variable_get(:@products).delete(product_key)
    end
  end

  # --- Boot-time registration validation tests ---

  test "RouteDrawer.draw handles zero products without error" do
    empty_registry = Pave::ProductRegistry.new
    scope_calls = []
    route_calls = []

    router = Object.new
    router.define_singleton_method(:scope) do |path = nil, defaults: nil, **, &block|
      scope_calls << { path: path, defaults: defaults }
      block&.call if block
    end
    router.define_singleton_method(:get) { |*args| route_calls << args }

    Pave.stub(:products, empty_registry) do
      Pave::Backoffice::RouteDrawer.draw(router)
    end

    assert_equal 0, scope_calls.size, "Expected no product scopes with zero products"
    assert_equal 0, route_calls.size, "Expected no routes with zero products"
  end

  test "RouteDrawer.draw creates product dashboard route for registered product" do
    product_key = :"test_route_product"
    scope_calls = []
    route_calls = []

    router = Object.new
    router.define_singleton_method(:scope) do |path = nil, defaults: nil, **, &block|
      scope_calls << { path: path, defaults: defaults }
      block&.call if block
    end
    %i[get post patch put delete].each do |verb|
      router.define_singleton_method(verb) { |*args| route_calls << args }
    end

    begin
      Pave.product(product_key, label: "Test Route Product", root: Rails.root.join("tmp"))

      Pave::Backoffice::RouteDrawer.draw(router)

      product_scope = scope_calls.find { |s| s[:path] == "/test_route_product" }
      assert product_scope, "Expected scope for product key"
      assert_equal "test_route_product", product_scope[:defaults][:product_id]

      dashboard_route = route_calls.find do |args|
        args[0] == "/" && args[1].is_a?(Hash) && args[1][:to] == "products/dashboard#show"
      end
      assert dashboard_route, "Expected dashboard route"
    ensure
      Pave.products.instance_variable_get(:@products).delete(product_key)
    end
  end

  test "RouteDrawer.draw creates panel routes for registered product panels" do
    product_key = :"test_panel_product"
    scope_calls = []
    route_calls = []

    router = Object.new
    router.define_singleton_method(:scope) do |path = nil, defaults: nil, **, &block|
      scope_calls << { path: path, defaults: defaults }
      block&.call if block
    end
    %i[get post patch put delete].each do |verb|
      router.define_singleton_method(verb) { |*args| route_calls << args }
    end

    registry = Pave::Backoffice.registry

    begin
      Pave.product(product_key, label: "Test Panel Product", root: Rails.root.join("tmp"))
      registry.register_product_panel(product_key, :widgets,
        label: "Widgets",
        controller: "pave/backoffice/base_controller",
        position: 10
      )

      Pave::Backoffice::RouteDrawer.draw(router)

      dashboard_route = route_calls.find do |args|
        args[0] == "/" && args[1].is_a?(Hash) && args[1][:to] == "products/dashboard#show"
      end
      assert dashboard_route, "Expected dashboard route"

      panel_route = route_calls.find { |args| args[0] == "/widgets" }
      assert panel_route, "Expected panel route for /widgets"
      assert_equal "base_controller#index", panel_route[1][:to]
    ensure
      registry.instance_variable_get(:@product_panels).delete(product_key)
      Pave.products.instance_variable_get(:@products).delete(product_key)
    end
  end

  # --- Panel metadata and default tests ---

  test "Panel defaults for missing optional metadata" do
    panel = Pave::Backoffice::Panel.new(name: :test_defaults, label: "Test Defaults")

    assert_equal 99, panel.position
    assert_nil panel.controller
    assert_nil panel.source
    assert_nil panel.source_package
    assert_nil panel.description
    assert_nil panel.status
    assert_nil panel.diagnostics
    assert_nil panel.route_block
    assert_nil panel.route
    assert_nil panel.capability
    assert_nil panel.group
    assert_nil panel.icon
  end

  # --- Navigation context tests ---

  test "navigation groups panels by group" do
    panels = [
      Pave::Backoffice::Panel.new(name: :users, label: "Users", group: :platform),
      Pave::Backoffice::Panel.new(name: :spaces, label: "Spaces", group: :products),
      Pave::Backoffice::Panel.new(name: :settings, label: "Settings", group: :platform)
    ]

    navigation = Pave::Backoffice::Navigation.new(panels: panels)
    groups = navigation.grouped

    assert_equal 2, groups.keys.size
    assert_equal 2, groups[:platform].size
    assert_equal 1, groups[:products].size
  end

  test "navigation with authorizer filters panels by capability" do
    panels = [
      Pave::Backoffice::Panel.new(name: :admin, label: "Admin", capability: "admin.access"),
      Pave::Backoffice::Panel.new(name: :public, label: "Public", capability: nil)
    ]

    authorizer = ->(panel) {
      capability = panel.respond_to?(:capability) ? panel.capability : nil
      capability ? capability == "admin.access" : true
    }

    navigation = Pave::Backoffice::Navigation.new(panels: panels, authorizer: authorizer)
    assert_equal [ :admin, :public ], navigation.panels.map(&:key)
  end
end
