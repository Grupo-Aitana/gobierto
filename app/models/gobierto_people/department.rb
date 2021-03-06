# frozen_string_literal: true

require_dependency "gobierto_people"

module GobiertoPeople
  class Department < ApplicationRecord
    include GobiertoCommon::Metadatable
    include GobiertoCommon::UrlBuildable

    include GobiertoCommon::Sluggable

    belongs_to :site
    has_many :events, class_name: "GobiertoCalendars::Event"
    has_many :gifts
    has_many :invitations
    has_many :trips

    scope :sorted, -> { order(name: :asc) }

    validates :name, presence: true

    def to_param
      slug
    end

    def parameterize
      { id: slug }
    end

    def attributes_for_slug
      [name]
    end

    def people
      site.people
          .joins(attending_person_events: :event)
          .where("gc_events.department_id = ?", id)
          .distinct
    end
  end
end
