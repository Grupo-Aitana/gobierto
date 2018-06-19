# frozen_string_literal: true

module GobiertoPeople
  module People
    class PastPersonEventsController < People::PersonEventsController

      def index
        if params[:date]
          @filtering_date = Date.parse(params[:date])
          @events = @person.events.by_date(@filtering_date).sorted.page params[:page]
        else
          @events = @person.events.past.sorted.page params[:page]
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
