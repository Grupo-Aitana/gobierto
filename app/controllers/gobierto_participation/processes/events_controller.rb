# frozen_string_literal: true

module GobiertoParticipation
  module Processes
    class EventsController < BaseController
      include ::PreviewTokenHelper

      def show
        @event = find_event

        set_events
      end

      def index
        @issues = current_site.issues

        @issue = find_issue if params[:issue_id]

        set_events

        respond_to do |format|
          format.html
          format.js
        end
      end

      private

      def find_issue
        current_site.issues.find_by_slug!(params[:issue_id])
      end

      def find_process_events
        ::GobiertoCalendars::Event.events_in_collections_and_container(current_site, current_process).sorted
      end

      def find_event
        find_process_events.find_by_slug!(params[:id])
      end

      def find_process_events
        @container_events = ::GobiertoCalendars::Event.events_in_collections_and_container_with_pending(current_site, current_process)
      end

      def set_events
        @events = find_process_events.sorted
        @events = @events.events_in_collections_and_container(current_site, @issue) if @issue

        @events = if params[:date]
                    filter_events_by_date(params[:date])
                  else
                    if @past_events
                      @events.past.sorted_backwards
                    else
                      if @events.upcoming.empty?
                        @no_upcoming_events = true
                        @events.past.sorted_backwards
                      else
                        @events.upcoming.sorted
                      end
                    end
                  end

        @events = @events.page params[:page]
        @calendar_events = @container_events
      end

      def filter_events_by_date(date)
        @filtering_date = Date.parse(date)
        events = @container_events.by_date(@filtering_date)
        events = (@filtering_date >= Time.now ? events.sorted : events.sorted_backwards)
      rescue ArgumentError
        events
      end
    end
  end
end
