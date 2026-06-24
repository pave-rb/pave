# frozen_string_literal: true

module Backoffice
  class RegistrationSettingsController < BaseController
    def show
      @registration_setting = RegistrationSetting.current
    end

    def enable
      registration_setting = RegistrationSetting.current
      registration_setting.update!(enabled: true)
      audit_toggle!(enabled: true)

      redirect_to backoffice_registrations_path, notice: t("backoffice.registrations.enable.notice")
    end

    def disable
      registration_setting = RegistrationSetting.current
      registration_setting.update!(enabled: false)
      audit_toggle!(enabled: false)

      redirect_to backoffice_registrations_path, notice: t("backoffice.registrations.disable.notice")
    end

    private

    def audit_toggle!(enabled:)
      AuditLogs::EventLogger.call(
        event_type: enabled ? "backoffice.registrations_enabled" : "backoffice.registrations_disabled",
        actor: real_current_user,
        request: request,
        metadata: audit_context_metadata.merge(surface: "backoffice_registrations", enabled:)
      )
    end
  end
end
