# frozen_string_literal: true

module GobiertoCommon
  class CollectionItem < ApplicationRecord
    belongs_to :collection
    belongs_to :item, polymorphic: true
    belongs_to :container, polymorphic: true

    after_commit :reindex_page, on: [:create, :update]

    scope :news, -> { where(item_type: 'GobiertoCms::News') }
    scope :pages, -> { where(item_type: %w(GobiertoCms::Page GobiertoCms::News)) }
    scope :attachments, -> { where(item_type: 'GobiertoAttachments::Attachment') }
    scope :events, -> { where(item_type: 'GobiertoCalendars::Event') }
    scope :issues, -> { where(item_type: 'Issue') }
    scope :pages_and_news, -> { where(item_type: %W(GobiertoCms::News GobiertoCms::Page)) }

    scope :by_container_type, ->(container_type) { where(container_type: container_type) }
    scope :by_container, ->(container) { where(container: container) }

    def container
      if container_id.present?
        super
      end
    end

    def item
      if item_type == "GobiertoCms::News"
        ::GobiertoCms::Page.find(item_id)
      else
        super
      end
    end

    private

    def reindex_page
      if item_type == "GobiertoCms::News" || item_type == "GobiertoCms::Page"
        ::GobiertoCms::Page.trigger_reindex_job(item, false)
      end
    end
  end
end
