# frozen_string_literal: true

module Spaces
  class UserPicturesController < Spaces::BaseController
    def show
      user = current_tenant.users.find(params[:user_id])
      stored_file = user.profile_picture_file
      return head :not_found if stored_file.blank?

      data = StoredFiles.storage_by_name(stored_file.storage_adapter).download(key: stored_file.storage_path)
      return head :not_found if data.blank?

      send_data data, type: stored_file.content_type, disposition: :inline
    end
  end
end
