module Pave
  module Backoffice
    module Platform
      class UsersController < Pave::Backoffice::BaseController
        PER_PAGE = 20

        def index
          @users = User.includes(:space_membership).order(:email)

          @users = @users.where("name ILIKE :q OR email ILIKE :q", q: "%#{params[:q]}%") if params[:q].present?
          @users = @users.where(system_role: :super_admin) if params[:platform_access].present?
          @users = @users.where.not(confirmed_at: nil) if params[:status] == "confirmed"
          @users = @users.where(confirmed_at: nil) if params[:status] == "unconfirmed"

          @users = @users.page(params[:page]).per(PER_PAGE)
        end

        def show
          @user = User.find(params[:id])

          @recent_events = Pave::Audit::AuditEvent.where(
            "(actor_type = ? AND actor_id = ?) OR (target_type = ? AND target_id = ?)",
            "User", @user.id, "User", @user.id
          ).order(occurred_at: :desc).limit(10)
        end

        def grant_super_admin
          @user = User.find(params[:id])

          if @user.super_admin?
            redirect_to pave_backoffice.user_path(@user), notice: "#{@user.email} is already a super admin."
            return
          end

          @user.update!(system_role: :super_admin)
          audit_admin("backoffice.super_admin.granted", target: @user, metadata: { email: @user.email })

          redirect_to pave_backoffice.user_path(@user), notice: "#{@user.email} is now a super admin."
        end

        def revoke_super_admin
          @user = User.find(params[:id])

          unless @user.super_admin?
            redirect_to pave_backoffice.user_path(@user), notice: "#{@user.email} is not a super admin."
            return
          end

          if @user == current_admin && User.where(system_role: :super_admin).count <= 1
            redirect_to pave_backoffice.user_path(@user), alert: "Cannot revoke your own super admin access. You are the last super admin."
            return
          end

          @user.update!(system_role: nil)
          audit_admin("backoffice.super_admin.revoked", target: @user, metadata: { email: @user.email })

          redirect_to pave_backoffice.user_path(@user), notice: "#{@user.email} is no longer a super admin."
        end
      end
    end
  end
end
