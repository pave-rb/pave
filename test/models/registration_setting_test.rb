# frozen_string_literal: true

require "test_helper"

class RegistrationSettingTest < ActiveSupport::TestCase
  setup do
    RegistrationSetting.delete_all
  end

  test "current returns an enabled singleton record" do
    setting = RegistrationSetting.current

    assert setting.persisted?
    assert setting.enabled?
    assert_equal setting, RegistrationSetting.current
    assert_equal 1, RegistrationSetting.count
  end

  test "enabled reflects the current registration switch" do
    assert RegistrationSetting.enabled?

    RegistrationSetting.current.update!(enabled: false)

    assert_not RegistrationSetting.enabled?
  end
end
