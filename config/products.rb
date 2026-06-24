# frozen_string_literal: true

# Product registrations go here.
#
# The DemoProduct dummy product lives under test/dummy/products/ and is
# always registered to exercise runtime contracts during development and test.

Pave.configure do |config|
  config.product :demo_scheduling,
    label: "Demo Scheduling",
    root: Rails.root.join("test/dummy/products/demo_scheduling")
end
