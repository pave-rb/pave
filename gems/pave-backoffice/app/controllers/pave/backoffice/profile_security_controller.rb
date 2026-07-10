# frozen_string_literal: true

module Pave
  module Backoffice
    class ProfileSecurityController < ProfileSecurity::BaseController
      before_action :load_security_overview

      def show
      end
    end
  end
end
