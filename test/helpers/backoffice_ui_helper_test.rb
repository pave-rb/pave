# frozen_string_literal: true

require "test_helper"

class BackofficeUiHelperTest < ActionView::TestCase
  include Pave::Backoffice::UiHelper

  test "context badge labels match supported variants" do
    assert_equal "Platform", backoffice_context_badge_text(:platform)
    assert_equal "Product · Demo", backoffice_context_badge_text(:product, "Demo")
    assert_equal "Plugin · whatsapp_channel", backoffice_context_badge_text(:plugin, "whatsapp_channel")
    assert_equal "Runtime module · pave-billing", backoffice_context_badge_text(:runtime_module, "pave-billing")
  end

  test "context badge variants render expected text" do
    assert_includes render_context_badge(:platform), "Platform"
    assert_includes render_context_badge(:product, "Demo"), "Product · Demo"
    assert_includes render_context_badge(:plugin, "whatsapp_channel"), "Plugin · whatsapp_channel"
    assert_includes render_context_badge(:runtime_module, "pave-billing"), "Runtime module · pave-billing"
  end

  test "table column defaults header from key" do
    column = backoffice_table_column(:email)
    assert_equal "email", column.key
    assert_equal "Email", column.header
    assert_nil column.cell
  end

  test "table column accepts custom header and cell block" do
    column = backoffice_table_column(:name, header: "Full name") { |record| record.to_s }
    assert_equal "name", column.key
    assert_equal "Full name", column.header
    assert_respond_to column.cell, :call
  end

  test "data table renders populated state" do
    html = render_data_table(records: [OpenStruct.new(name: "Ada")]) do |table|
      table.with_column(:name, header: "Name") { |record| record.name }
    end

    assert_includes html, "Ada"
    assert_includes html, "Name"
    assert_includes html, "data-backoffice-data-table"
    assert_includes html, "<tbody"
    refute_includes html, "No records found."
  end

  test "data table renders empty state" do
    html = render_data_table(records: [], empty_message: "Nothing here.") do |table|
      table.with_column(:name, header: "Name") { |record| record.name }
    end

    assert_includes html, "Nothing here."
    assert_includes html, "data-backoffice-empty-state"
  end

  test "filter bar renders fields and buttons" do
    html = Pave::Backoffice::BaseController.render(
      partial: "pave/backoffice/components/filter_bar",
      locals: { url: "/admin/users", clear_url: "/admin/users" }
    ) do
      "<input type=\"text\" name=\"q\">".html_safe
    end

    assert_includes html, "Filter"
    assert_includes html, "Clear"
    assert_includes html, "data-backoffice-filter-bar=\"true\""
  end

  test "empty state renders default correctly_empty variant" do
    html = render_empty_state

    assert_includes html, "Nothing here"
    assert_includes html, "data-backoffice-empty-state=\"correctly_empty\""
  end

  test "empty state renders missing_configuration variant" do
    html = render_empty_state(variant: :missing_configuration, title: "No settings declared")

    assert_includes html, "No settings declared"
    assert_includes html, "data-backoffice-empty-state=\"missing_configuration\""
    assert_includes html, "Required configuration is missing"
  end

  test "empty state renders action links" do
    html = render_empty_state(action: ["View docs", "/docs"], secondary_action: ["Run doctor", "/doctor"])

    assert_includes html, "View docs"
    assert_includes html, "/docs"
    assert_includes html, "Run doctor"
    assert_includes html, "/doctor"
  end

  test "drawer renders with Stimulus controller and close link" do
    html = Pave::Backoffice::BaseController.render(
      partial: "pave/backoffice/components/drawer",
      locals: { id: "test-drawer", title: "Drawer title", close_path: "/admin/audit" }
    )

    assert_includes html, "data-controller=\"pave--backoffice--drawer\""
    assert_includes html, "Drawer title"
    assert_includes html, "/admin/audit"
    assert_includes html, "data-pave--backoffice--drawer-target=\"panel\""
    assert_includes html, "data-pave--backoffice--drawer-target=\"content\""
    assert_includes html, "click->pave--backoffice--drawer#backdropClose"
  end

  test "confirmation modal blocks submit until required confirmation is satisfied" do
    html = Pave::Backoffice::BaseController.render(
      partial: "pave/backoffice/components/confirmation_modal",
      locals: {
        id: "test-modal",
        title: "Revoke access",
        impact: "This will remove platform access.",
        affected: "Admin user",
        confirmation_input: true,
        confirmation_value: "revoke",
        form_options: { url: "/admin/users/1/revoke", method: :post }
      }
    )

    assert_includes html, "data-controller=\"pave--backoffice--modal\""
    assert_includes html, "Revoke access"
    assert_includes html, "data-pave--backoffice--modal-target=\"submit\""
    assert_includes html, "data-pave--backoffice--modal-target=\"confirmation\""
    assert_includes html, "revoke"
    assert_includes html, "/admin/users/1/revoke"
    assert_includes html, "disabled=\"disabled\""
  end

  test "secret field masks by default and shows source state" do
    html = Pave::Backoffice::BaseController.render(
      partial: "pave/backoffice/components/secret_field",
      locals: {
        name: "settings[api_key]",
        id: "settings_api_key",
        value_present: true,
        source: :database,
        required: true
      }
    )

    assert_includes html, "data-controller=\"pave--backoffice--secret-field\""
    assert_includes html, "••••••••"
    refute_includes html, "database-secret"
    assert_includes html, "Database"
    assert_includes html, "data-pave--backoffice--secret-field-source-value=\"database\""
  end

  test "secret field shows missing state when no value present" do
    html = Pave::Backoffice::BaseController.render(
      partial: "pave/backoffice/components/secret_field",
      locals: {
        name: "settings[api_key]",
        value_present: false,
        source: :missing,
        required: false
      }
    )

    assert_includes html, "Not set"
    assert_includes html, "Missing"
    refute_includes html, "Clear stored secret"
  end

  private

  def render_context_badge(variant, label = nil)
    Pave::Backoffice::BaseController.render(
      partial: "pave/backoffice/components/context_badge",
      locals: { variant: variant, label: label }
    )
  end

  def render_data_table(records:, empty_message: "No records found.", &block)
    Pave::Backoffice::BaseController.render(
      partial: "pave/backoffice/components/data_table",
      locals: { records: records, empty_message: empty_message, columns: build_columns(&block) }
    )
  end

  def render_empty_state(variant: :correctly_empty, **locals)
    Pave::Backoffice::BaseController.render(
      partial: "pave/backoffice/components/empty_state",
      locals: { variant: variant, **locals }
    )
  end

  def build_columns
    builder = TableColumnBuilder.new
    yield builder if block_given?
    builder.columns
  end

  class TableColumnBuilder
    attr_reader :columns

    def initialize
      @columns = []
    end

    def with_column(key, header: nil, classes: nil, &block)
      @columns << Pave::Backoffice::TableColumn.new(key: key, header: header, cell: block, classes: classes)
    end
  end
end
