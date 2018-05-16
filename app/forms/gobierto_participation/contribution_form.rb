# frozen_string_literal: true

module GobiertoParticipation
  class ContributionForm < BaseForm

    attr_accessor(
      :id,
      :site_id,
      :user_id,
      :contribution_container_id,
      :title,
      :description
    )

    delegate :persisted?, to: :contribution

    validates :title, presence: true, length: { maximum: 140 }
    validate :contribution_container_must_be_open

    def save
      save_contribution if valid?
    end

    def contribution
      @contribution ||= contribution_class.find_by(id: id).presence || build_contribution
    end

    def site_id
      @site_id ||= contribution.site_id
    end

    def site
      @site ||= Site.find_by(id: site_id)
    end

    def contribution_container
      @contribution_container ||= ContributionContainer.find_by(id: contribution_container_id)
    end

    private

    def build_contribution
      contribution_class.new
    end

    def contribution_class
      ::GobiertoParticipation::Contribution
    end

    def save_contribution
      @contribution = contribution.tap do |contribution_attributes|
        contribution_attributes.site_id = site_id
        contribution_attributes.user_id = user_id
        contribution_attributes.contribution_container_id = contribution_container_id
        contribution_attributes.title = title
        contribution_attributes.description = description
      end

      if @contribution.save
        @contribution
      else
        promote_errors(@contribution.errors)

        false
      end
    end

    def contribution_container_must_be_open
      unless contribution_container.contributions_allowed?
        errors.add(:contribution_container, 'Contributions period has finished')
      end
    end

  end
end
