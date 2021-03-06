# frozen_string_literal: true

module GobiertoParticipation
  class AttachmentsController < GobiertoParticipation::ApplicationController
    def index
      @issue = find_issue if params[:issue_id]
      @issues = current_site.issues
      @filtered_issue = find_issue if params[:issue_id]
      @attachments = if @filtered_issue
                       GobiertoAttachments::Attachment.attachments_in_collections_and_container(current_site, @issue).page(params[:page])
                     else
                       find_attachments.page(params[:page])
                     end
    end

    private

    def find_issue
      current_site.issues.find_by_slug!(params[:issue_id])
    end

    def find_attachments
      attachments = ::GobiertoAttachments::Attachment.attachments_in_collections_and_container_type(current_site, "GobiertoParticipation")

      if @filtered_issue
        attachments = attachments.attachments_in_collections_and_container(current_site, @filtered_issue)
      end

      attachments
    end
  end
end
