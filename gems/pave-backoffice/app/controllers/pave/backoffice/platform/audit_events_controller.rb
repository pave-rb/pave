module Pave
  module Backoffice
    module Platform
      class AuditEventsController < Pave::Backoffice::BaseController
        PER_PAGE = 50

        def index
          @events = filtered_events
          @distinct_sources = Pave::Audit::AuditEvent.distinct.where.not(source: nil).order(:source).pluck(:source)
          @distinct_keys = Pave::Audit::AuditEvent.distinct.order(:key).pluck(:key)
          @distinct_target_types = Pave::Audit::AuditEvent.distinct.where.not(target_type: nil).order(:target_type).pluck(:target_type)
        end

        def show
          @event = Pave::Audit::AuditEvent.find(params[:id])
        end

        private

        def filtered_events
          scope = Pave::Audit::AuditEvent.order(occurred_at: :desc)

          scope = scope.where("occurred_at >= ?", Time.zone.parse(params[:from_date]).beginning_of_day) if params[:from_date].present?
          scope = scope.where("occurred_at <= ?", Time.zone.parse(params[:to_date]).end_of_day) if params[:to_date].present?

          if params[:key].present?
            scope = scope.where("key ILIKE ?", "%#{params[:key]}%")
          end

          if params[:actor].present?
            scope = scope.where(
              "actor_label ILIKE :q OR CAST(actor_id AS TEXT) LIKE :q",
              q: "%#{params[:actor]}%"
            )
          end

          if params[:target_type].present?
            scope = scope.where(target_type: params[:target_type])
          end

          if params[:source].present?
            scope = scope.where(source: params[:source])
          end

          if params[:product].present?
            if params[:product] == "backoffice"
              scope = scope.where(space_id: nil)
            else
              scope = scope.where.not(space_id: nil)
            end
          end

          if params[:mutation_only] == "1"
            scope = scope.where("key NOT ILIKE ?", "read.%")
          end

          if params[:namespace].present?
            scope = scope.where("key ILIKE ?", "#{params[:namespace]}.%")
          end

          scope.page(params[:page]).per(PER_PAGE)
        end
      end
    end
  end
end
