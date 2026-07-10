# frozen_string_literal: true

require "uri"

class AddRpIdToUserPasskeys < ActiveRecord::Migration[8.1]
  class Passkey < ActiveRecord::Base
    self.table_name = "user_passkeys"
  end

  def up
    add_column :user_passkeys, :rp_id, :string

    Passkey.reset_column_information
    Passkey.unscoped.update_all(rp_id: legacy_rp_id)

    change_column_null :user_passkeys, :rp_id, false
    add_index :user_passkeys, [ :user_id, :rp_id ]
  end

  def down
    remove_index :user_passkeys, column: [ :user_id, :rp_id ]
    remove_column :user_passkeys, :rp_id
  end

  private

  def legacy_rp_id
    ENV["WEBAUTHN_RP_ID"].presence ||
      ENV["WEBAUTHN_PRODUCT_RP_ID"].presence ||
      host_from_origin(ENV["APP_BASE_URL"].presence) ||
      host_from_origin(ENV["APP_BASE_URLS"].to_s.split(",").first.presence) ||
      "localhost"
  end

  def host_from_origin(origin)
    return if origin.blank?

    URI.parse(origin).host.presence
  rescue URI::InvalidURIError
    nil
  end
end
