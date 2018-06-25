# frozen_string_literal: true

module GobiertoPeople
  class WelcomeController < GobiertoPeople::ApplicationController
    include PoliticalGroupsHelper
    include PeopleClassificationHelper
    include DatesRangeHelper

    before_action :check_active_submodules

    def index
      @people = current_site.people.active.politician.government.sorted.first(10)
      @posts  = current_site.person_posts.active.sorted.last(10)
      @political_groups = get_political_groups
      @home_text = load_home_text
      set_events
      set_present_groups

      # TODO: this info is only needed for custom engine
      @gifts = current_site.gifts.limit(4).between_dates(filter_start_date, filter_end_date)
      @invitations = current_site.invitations.limit(4).between_dates(filter_start_date, filter_end_date)
      load_home_statistics
    end

    private

    def check_active_submodules
      if active_submodules.size == 1
        redirect_to submodule_path_for(active_submodules.first)
      end
    end

    def set_events
      @events = GobiertoCalendars::Event.by_site(current_site).person_events.by_person_party(Person.parties[:government]).limit(10)

      @events = @events.upcoming.sorted
      if @events.empty?
        @no_upcoming_events = true
        @events = @events.past.sorted_backwards
      end
    end

    def load_home_text
      current_site.gobierto_people_settings&.send("home_text_#{I18n.locale}")
    end

    def load_home_statistics
      people = QueryWithEvents.new(source: current_site.event_attendances,
                                   start_date: filter_start_date,
                                   end_date: filter_end_date,
                                   not_null: [:department_id])
      interest_groups = QueryWithEvents.new(source: current_site.interest_groups,
                                            start_date: filter_start_date,
                                            end_date: filter_end_date)
      @home_statistics = {
        total_events: people.relation.count,
        total_interest_groups: interest_groups.relation.count,
        total_people_with_attendances: people.relation.select(:person_id).distinct.count
      }
    end
  end
end
