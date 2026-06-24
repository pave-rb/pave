# frozen_string_literal: true

require "test_helper"

class PwaDirectivesTest < ActionDispatch::IntegrationTest
  test "application layout includes required pwa head tags" do
    get new_user_session_path

    assert_response :success
    assert_pwa_head
  end

  test "landing layout includes required pwa head tags" do
    get root_path

    assert_response :success
    assert_pwa_head
  end

  test "booking layout includes required pwa head tags" do
    get book_path(token: scheduling_links(:permanent_link).token)

    assert_response :success
    assert_pwa_head
  end

  test "onboarding layout includes required pwa head tags" do
    sign_in users(:manager)

    get onboarding_wizard_path

    assert_response :success
    assert_pwa_head
  end

  test "manifest is installable and references required icons" do
    get "/manifest.webmanifest"

    assert_response :success

    manifest = JSON.parse(response.body)
    assert_equal "Pavê", manifest.fetch("name")
    assert_equal "Pavê", manifest.fetch("short_name")
    assert_equal "/", manifest.fetch("start_url")
    assert_equal "standalone", manifest.fetch("display")
    assert_equal "#ffffff", manifest.fetch("background_color")
    assert_equal "#007AFF", manifest.fetch("theme_color")
    assert_includes manifest.fetch("icons"), {
      "src" => "/icon-192.png",
      "sizes" => "192x192",
      "type" => "image/png"
    }
    assert_includes manifest.fetch("icons"), {
      "src" => "/icon-512.png",
      "sizes" => "512x512",
      "type" => "image/png"
    }
    assert_includes manifest.fetch("icons"), {
      "src" => "/icon-512.png",
      "sizes" => "512x512",
      "type" => "image/png",
      "purpose" => "maskable"
    }

    assert File.exist?(Rails.root.join("public/icon-180.png"))
    assert File.exist?(Rails.root.join("public/icon-192.png"))
    assert File.exist?(Rails.root.join("public/icon-512.png"))
  end

  private

  def assert_pwa_head
    assert_select "meta[name='viewport'][content='width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no']", count: 1
    assert_select "meta[name='mobile-web-app-capable'][content='yes']", count: 1
    assert_select "meta[name='apple-mobile-web-app-capable'][content='yes']", count: 1
    assert_select "meta[name='apple-mobile-web-app-status-bar-style'][content='black-translucent']", count: 1
    assert_select "meta[name='apple-mobile-web-app-title'][content='Pavê']", count: 1
    assert_select "meta[name='theme-color'][content='#007AFF']", count: 1
    assert_select "link[rel='manifest'][href='/manifest.webmanifest']", count: 1
    assert_select "link[rel='icon'][href='/icon.png'][type='image/png']", count: 1
    assert_select "link[rel='icon'][href='/icon.svg'][type='image/svg+xml']", count: 1
    assert_select "link[rel='apple-touch-icon'][href='/icon-180.png']", count: 1
  end
end
