# frozen_string_literal: true

require "test_helper"

module Pave
  module Backoffice
    module Platform
      class AuditEventsTest < ActionDispatch::IntegrationTest
        setup do
          @admin = users(:admin)
          @manager = users(:manager)

          Pave::Audit::AuditEvent.delete_all

          @event1 = Pave::Audit::AuditEvent.create!(
            key: "backoffice.super_admin.granted",
            actor_type: "User",
            actor_id: @admin.id,
            actor_label: @admin.email,
            target_type: "User",
            target_id: @manager.id,
            target_label: @manager.email,
            source: "backoffice",
            space_id: nil,
            metadata: { backoffice: true },
            occurred_at: 2.days.ago
          )

          @event2 = Pave::Audit::AuditEvent.create!(
            key: "user.sign_in",
            actor_type: "User",
            actor_id: @manager.id,
            actor_label: @manager.email,
            source: "web",
            space_id: nil,
            metadata: { ip: "127.0.0.1" },
            occurred_at: 1.day.ago
          )

          @event3 = Pave::Audit::AuditEvent.create!(
            key: "product.order.created",
            actor_type: "User",
            actor_id: @manager.id,
            actor_label: @manager.email,
            target_type: "User",
            target_id: @manager.id,
            target_label: @manager.email,
            source: "product",
            space_id: 1,
            metadata: { order_id: 42 },
            occurred_at: 6.hours.ago
          )
        end

        def sign_in_to_backoffice
          post "/admin/sign_in", params: { email: @admin.email, password: "password123" }
          assert_redirected_to "/admin/"
        end

    test "audit index renders for platform admin" do
      sign_in_to_backoffice
      get "/admin/audit"
      assert_response :success
      assert_select "h1", "Audit Log"
      assert_select "[data-backoffice-filter-bar]"
      assert_select "[data-backoffice-data-table]"
    end

        test "audit index lists audit events" do
          sign_in_to_backoffice
          get "/admin/audit"
          assert_response :success
          assert_select "tbody tr", count: 3
          assert_select "td code", text: "backoffice.super_admin.granted"
          assert_select "td code", text: "user.sign_in"
          assert_select "td code", text: "product.order.created"
        end

        test "audit index requires backoffice authentication" do
          get "/admin/audit"
          assert_redirected_to "/admin/sign_in"
        end

    test "audit index filters by event key" do
      sign_in_to_backoffice
      get "/admin/audit", params: { key: "super_admin" }
      assert_response :success
      assert_select "tbody tr", count: 1
      assert_select "td code", text: "backoffice.super_admin.granted"
      assert_select "[data-backoffice-filter-chips]", text: /Key:.*super_admin/
    end

        test "audit index filters by actor" do
          sign_in_to_backoffice
          get "/admin/audit", params: { actor: @manager.email }
          assert_response :success
          assert_select "tbody tr", count: 2
        end

        test "audit index filters by source" do
          sign_in_to_backoffice
          get "/admin/audit", params: { source: "backoffice" }
          assert_response :success
          assert_select "tbody tr", count: 1
          assert_select "td code", text: "backoffice.super_admin.granted"
        end

        test "audit index filters by target type" do
          sign_in_to_backoffice
          get "/admin/audit", params: { target_type: "User" }
          assert_response :success
          assert_select "tbody tr", count: 2
        end

        test "audit index filters by context backoffice only" do
          sign_in_to_backoffice
          get "/admin/audit", params: { product: "backoffice" }
          assert_response :success
          assert_select "tbody tr", count: 2
          assert_select "td code", text: "backoffice.super_admin.granted"
          assert_select "td code", text: "user.sign_in"
        end

        test "audit index filters by context product only" do
          sign_in_to_backoffice
          get "/admin/audit", params: { product: "product" }
          assert_response :success
          assert_select "tbody tr", count: 1
          assert_select "td code", text: "product.order.created"
        end

        test "audit index filters by date range" do
          sign_in_to_backoffice
          get "/admin/audit", params: { from_date: 3.days.ago.to_date.to_s, to_date: 1.day.ago.to_date.to_s }
          assert_response :success
          assert_select "tbody tr", count: 2
        end

        test "audit index mutation only filter excludes read events" do
          Pave::Audit::AuditEvent.create!(
            key: "read.dashboard",
            actor_type: "User",
            actor_id: @admin.id,
            source: "backoffice",
            metadata: {},
            occurred_at: 1.hour.ago
          )

          sign_in_to_backoffice
          get "/admin/audit", params: { mutation_only: "1" }
          assert_response :success
          assert_select "td code", text: "backoffice.super_admin.granted"
          assert_select "td code", text: "user.sign_in"
          assert_select "td code", text: "product.order.created"
          assert_select "td code", text: "read.dashboard", count: 0
        end

        test "audit index shows platform context badge for backoffice events" do
          sign_in_to_backoffice
          get "/admin/audit"
          assert_response :success
          assert_select "td span", text: "Platform", count: 2
          assert_select "td span", text: "Product", count: 1
        end

        test "audit index shows empty state when no results" do
          sign_in_to_backoffice
          get "/admin/audit", params: { key: "nonexistent" }
          assert_response :success
          assert_select "td", text: "No audit events found."
        end

        test "audit index accepts page parameter without error" do
          sign_in_to_backoffice
          get "/admin/audit", params: { page: 1 }
          assert_response :success
        end

        test "audit index exposes inline detail drawer frame and row links" do
          sign_in_to_backoffice
          get "/admin/audit", params: { key: "super_admin" }
          assert_response :success

          assert_select "turbo-frame#audit_event_detail"
          assert_select "a[data-turbo-frame='audit_event_detail'][href*='/admin/audit/#{@event1.id}']"
          assert_select "a[data-turbo-frame='audit_event_detail'][href*='key=super_admin']"
        end

        test "audit event detail drawer renders event metadata" do
          sign_in_to_backoffice
          get "/admin/audit/#{@event1.id}", params: { key: "super_admin" }
          assert_response :success

          assert_select "turbo-frame#audit_event_detail"
          assert_select "[role='dialog'][aria-modal='true']"
          assert_select "h2", text: "backoffice.super_admin.granted"
          assert_select "dt", text: "Actor"
          assert_select "dd", text: @admin.email
          assert_select "dt", text: "Target"
          assert_select "dd", text: @manager.email
          assert_select "pre", text: /backoffice/
          assert_select "a[href='/admin/audit?key=super_admin']", text: "Close"
        end

        test "audit event detail drawer requires backoffice authentication" do
          get "/admin/audit/#{@event1.id}"
          assert_redirected_to "/admin/sign_in"
        end

        test "audit index responds to clear link" do
          sign_in_to_backoffice
          get "/admin/audit"
          assert_response :success
          assert_select "a[href='/admin/audit']", text: "Clear"
        end
      end
    end
  end
end
