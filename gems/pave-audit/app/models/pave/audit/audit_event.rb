# frozen_string_literal: true

module Pave
  module Audit
    class AuditEvent < ActiveRecord::Base
      self.table_name = "pave_audit_events"

      validates :key, presence: true
      validates :occurred_at, presence: true

      before_update { raise ActiveRecord::ReadOnlyRecord, "#{self.class} is append-only and cannot be updated" }
      before_destroy { raise ActiveRecord::ReadOnlyRecord, "#{self.class} is append-only and cannot be destroyed" }
    end
  end
end
