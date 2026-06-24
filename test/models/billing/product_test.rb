# frozen_string_literal: true

require "test_helper"

module Billing
  class ProductTest < ActiveSupport::TestCase
    test "valid product saves successfully" do
      product = Billing::Product.new(key: "new_product", name: "New Product", position: 10)

      assert product.valid?
    end

    test "key is required" do
      product = Billing::Product.new(name: "No Key", position: 1)

      assert_not product.valid?
      assert product.errors[:key].any?
    end

    test "key must be unique" do
      product = Billing::Product.new(key: billing_products(:crm).key, name: "Duplicate", position: 9)

      assert_not product.valid?
      assert product.errors[:key].any?
    end

    test "key must use lowercase letters numbers and underscores" do
      product = Billing::Product.new(key: "Bad Key!", name: "Bad", position: 1)

      assert_not product.valid?
      assert product.errors[:key].any?
    end

    test "name is required" do
      product = Billing::Product.new(key: "nameless", position: 1)

      assert_not product.valid?
      assert product.errors[:name].any?
    end

    test "position is required" do
      product = Billing::Product.new(key: "positionless", name: "Positionless", position: nil)

      assert_not product.valid?
      assert product.errors[:position].any?
    end

    test "crm returns the CRM product" do
      assert_equal billing_products(:crm), Billing::Product.crm
    end
  end
end
