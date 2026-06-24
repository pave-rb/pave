# frozen_string_literal: true

require "test_helper"

module Platform
  class ModulesTest < ActiveSupport::TestCase
    def setup
      Current.subscription = nil
    end

    def teardown
      Current.subscription = nil
    end

    test "registry includes CRM integrations and future vertical modules" do
      keys = Platform::Modules.all.map(&:key)

      assert_includes keys, "crm"
      assert_includes keys, "crm.inbox"
      assert_includes keys, "integrations.whatsapp"
      assert_includes keys, "peti_vet"
    end

    test "unknown module keys fail loudly" do
      assert_raises Platform::Modules::UnknownKey do
        Platform::Modules.visible?(space: spaces(:one), user: users(:manager), key: "crm.unknown")
      end
    end

    test "navigation shows inbox when billing and IAM both allow it" do
      assert Platform::Modules.visible?(space: spaces(:one), user: users(:secretary), key: "crm.inbox")
    end

    test "disabled commercial module is hidden but not treated as authorization failure" do
      assert Platform::Modules.authorized?(space: spaces(:one), user: users(:manager), key: "integrations.whatsapp")
      assert_not Platform::Modules.available?(space: spaces(:one), key: "integrations.whatsapp")
      assert_not Platform::Modules.visible?(space: spaces(:one), user: users(:manager), key: "integrations.whatsapp")
    end

    test "commercially available module is still hidden when IAM denies it" do
      assert Platform::Modules.available?(space: spaces(:two), key: "integrations.whatsapp")
      assert_not Platform::Modules.authorized?(space: spaces(:two), user: users(:secretary), key: "integrations.whatsapp")
      assert_not Platform::Modules.visible?(space: spaces(:two), user: users(:secretary), key: "integrations.whatsapp")
    end

    test "navigation_for returns only visible navigation modules" do
      keys = Platform::Modules.navigation_for(space: spaces(:one), user: users(:manager)).map(&:key)

      assert_includes keys, "crm.appointments"
      assert_includes keys, "crm.inbox"
      assert_not_includes keys, "integrations.whatsapp"
      assert_not_includes keys, "peti_vet"
    end

    test "future vertical module becomes visible through billing entitlement" do
      peti_plan = Billing::Plan.create!(
        billing_product: billing_products(:peti_vet),
        slug: "peti_modules",
        name: "Peti Modules",
        price_cents: 39999,
        features: [ "peti_vet_pets" ],
        position: 10
      )
      Billing::Subscription.create!(
        space: spaces(:one),
        billing_product: billing_products(:peti_vet),
        billing_plan: peti_plan,
        status: :active
      )

      assert Platform::Modules.visible?(space: spaces(:one), user: users(:manager), key: "peti_vet")
    end
  end
end
