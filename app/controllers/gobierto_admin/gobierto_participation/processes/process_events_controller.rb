# frozen_string_literal: true

module GobiertoAdmin
  module GobiertoParticipation
    module Processes
      class ProcessEventsController < Processes::BaseController
        def index
          @collection = current_process.events_collection
          @events_presenter = GobiertoAdmin::GobiertoCalendars::EventsPresenter.new(@collection)
          @events = ::GobiertoCalendars::Event.where(id: @collection.events_in_collection).sorted_backwards
          @archived_events = ::GobiertoCalendars::Event.only_archived.where(collection_id: @collection.id).sorted
        end
      end
    end
  end
end
