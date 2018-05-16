# frozen_string_literal: true

module GobiertoAdmin
  class IssueForm < BaseForm

    attr_accessor(
      :id,
      :site_id,
      :name_translations,
      :description_translations,
      :slug
    )

    delegate :persisted?, to: :issue

    validates :site, presence: true

    def save
      save_issue if valid?
    end

    def issue
      @issue ||= issue_class.find_by(id: id).presence || build_issue
    end

    def site_id
      @site_id ||= issue.site_id
    end

    def site
      @site ||= Site.find_by(id: site_id)
    end

    private

    def build_issue
      issue_class.new
    end

    def issue_class
      ::Issue
    end

    def save_issue
      @issue = issue.tap do |issue_attributes|
        issue_attributes.site_id = site_id
        issue_attributes.name_translations = name_translations
        issue_attributes.description_translations = description_translations
        issue_attributes.slug = slug
      end

      if @issue.valid?
        @issue.save

        @issue
      else
        promote_errors(@issue.errors)

        false
      end
    end

  end
end
