# frozen_string_literal: true

module GobiertoPeople
  module People
    class PastPersonEventsController < People::PersonEventsController

      def index
        if params[:date]
          @filtering_date = Date.parse(params[:date])
          @events = @person.events.by_date(@filtering_date).sorted.page params[:page]
        elsif params[:page] == "false"
          # permit non-pagination and avoid N+1 queries for custom engines
          @events = QueryWithEvents.new(source: @person.events,
                                        start_date: filter_start_date,
                                        end_date: filter_end_date).past.sorted_backwards.includes(:interest_group)
        else
          @events = QueryWithEvents.new(source: @person.events,
                                        start_date: filter_start_date,
                                        end_date: filter_end_date).upcoming.sorted.page params[:page]
        end

        respond_to do |format|
          format.js { render "#{views_path}index" }
          format.html { render "#{views_path}index" }
        end
      end

      private

      def views_path
        "gobierto_people/people/person_events/"
      end

    end
  end
end
