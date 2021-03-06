# frozen_string_literal: true

module GobiertoPlans
  class PlanTypesController < GobiertoPlans::ApplicationController
    include ::PreviewTokenHelper
    include User::SessionHelper

    before_action :load_plan_types, only: [:index]

    def index
      # HACK: select last plan which at least has one published plan to avoid https://github.com/PopulateTools/issues/issues/304
      @plan_type = @plan_types.select { |plan_type| plan_type.plans.published.any? }.last
      load_plans
      load_years
      @year = @years.first

      redirect_to gobierto_plans_plan_path(slug: @plan_type.slug, year: @year)
    end

    def show
      @plan_type = find_plan_type
      load_plans
      load_years
      load_year
      redirect_to gobierto_plans_plan_path(slug: params[:slug], year: @years.first) and return if @year.nil?
      @plan = find_plan

      @site_stats = GobiertoPlans::SiteStats.new site: current_site, plan: @plan
      @plan_updated_at = @site_stats.plan_updated_at

      respond_to do |format|
        format.html do
          @node_number = @plan.nodes.count
          @levels = @plan.levels
        end

        format.json do
          plan_tree = GobiertoPlans::PlanTree.new(@plan).call

          render(
            json: { plan_tree: plan_tree,
                    option_keys: @plan.configuration_data["option_keys"],
                    level_keys: level_keys,
                    show_table_header: @plan.configuration_data["show_table_header"],
                    open_node: @plan.configuration_data["open_node"] }
          )
        end
      end
    end

    private

    def find_plan_type
      current_site.plan_types.find_by!(slug: params[:slug])
    end

    def find_plan
      @plan_type.plans.find_by!(year: params[:year])
    end

    def level_keys
      @plan.configuration_data.select { |k| k =~ /level\d\z/ }
    end

    def load_plan_types
      @plan_types = current_site.plan_types.sort_by_updated_at
    end

    def load_plans
      @plans = @plan_type.plans.published
    end

    def load_years
      @years = @plans.pluck(:year).sort.reverse!
    end

    def load_year
      if params[:year]
        @year = params[:year].to_i
      end
    end
  end
end
