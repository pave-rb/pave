# frozen_string_literal: true

require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  # Stub Devise helpers that the helper method depends on
  attr_writer :signed_in, :stub_current_user

  def user_signed_in?
    @signed_in
  end

  def current_user
    @stub_current_user
  end

  setup do
    @signed_in         = false
    @stub_current_user = nil
  end

  test "app_name helper reads from shared brand settings" do
    assert_equal AppBrand.name, app_name
    assert_equal AppBrand.logo_asset, app_logo_asset
    assert_equal AppBrand.wordmark_asset, app_wordmark_asset
  end
end
