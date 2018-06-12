# frozen_string_literal: true

require_dependency "gobierto_people"

module GobiertoPeople
  class InterestGroup < ApplicationRecord

    include GobiertoCommon::Sluggable
    include GobiertoCommon::Metadatable

    belongs_to :site
    has_many :events, class_name: "GobiertoCalendars::Event", dependent: :nullify

    scope :sorted, -> { order(name: :asc) }

    validates :name, presence: true

    metadata_attributes :status, :registry

    def to_param
      slug
    end

    def attributes_for_slug
      [name]
    end

    def events_count
      attributes["events_count"] || events.count
    end

  end
end
