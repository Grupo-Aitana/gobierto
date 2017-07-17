module GobiertoBudgets
  class SiteStats
    def initialize(options)
      @site = options.fetch :site
      @place = @site.place
      @year = options.fetch(:year).to_i
      @data = {debt: {},population: {}}
    end

    def has_data?(variable, year)
      r = send(variable, year)
      r.present? && r != 0
    end

    def total_budget_per_inhabitant(year = nil)
      year ||= @year
      total_budget_per_inhabitant_query(year)['_source']['total_budget_per_inhabitant'].to_f
    end

    def total_income_budget(year = nil)
      year ||= @year
      BudgetTotal.budgeted_for(@place.id, year, BudgetLine::INCOME)
    end

    def total_budget(year = nil)
      year ||= @year
      BudgetTotal.budgeted_for(@place.id, year)
    end
    alias_method :total_budget_planned, :total_budget

    def total_budget_executed(year = nil)
      year ||= @year
      BudgetTotal.execution_for(@place.id, year)
    end

    def total_budget_executed_percentage(year = nil)
      execution_percentage(total_budget(year), total_budget_executed(year))
    end

    def debt(year = nil)
      year ||= @year
      @data[:debt][year] ||= SearchEngine.client.get(index: SearchEngineConfiguration::Data.index,
        type: SearchEngineConfiguration::Data.type_debt, id: [@place.id, year].join('/'))['_source']['value'] * 1000
      @data[:debt][year]
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      nil
    end

    def population(year = nil)
      year ||= @year
      @data[:population][year] ||= SearchEngine.client.get(index: SearchEngineConfiguration::Data.index,
        type: SearchEngineConfiguration::Data.type_population, id: [@place.id, year].join('/'))['_source']['value']
      @data[:population][year]
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        nil
    end

    def latest_available(variable, year = nil)
      year ||= @year
      value = []
      year.downto(2010).each do |y|
        if has_data?(variable, y)
          value = {value: send(variable,y), year: y}
          break
        end
      end
      value
    end

    def percentage_difference(options)
      year = options.fetch(:year, @year)
      variable1 = options.fetch(:variable1)
      variable2 = options.fetch(:variable2, options.fetch(:variable1))
      diff = if variable1 == variable2
        year1 = options.fetch(:year1)
        year2 = options.fetch(:year2)

        v1 = self.send(variable1, year1)
        v2 = self.send(variable1, year2)
        return nil if v1.nil? || v2.nil?

        ((v1.to_f - v2.to_f)/v2.to_f) * 100
      else
        v1 = self.send(variable1, year)
        v2 = self.send(variable2, year)
        return nil if v1.nil? || v2.nil?
        ((v1.to_f - v2.to_f)/v2.to_f) * 100
      end

      if(diff < 0)
        direction = I18n.t('gobierto_budgets.budgets.index.less')
        diff = diff*-1
      else
        direction = I18n.t('gobierto_budgets.budgets.index.more')
      end

      "#{ActionController::Base.helpers.number_with_precision(diff, precision: 2)}% #{direction}"
    end

    def main_budget_lines_summary
      main_budget_lines_forecast         = BudgetLine.all(where: { kind: BudgetLine::EXPENSE, level: 1, place: @site.place, year: @year, area_name: EconomicArea.area_name })
      main_budget_lines_execution        = BudgetLine.all(where: { kind: BudgetLine::EXPENSE, level: 1, place: @site.place, year: @year, area_name: EconomicArea.area_name, index: SearchEngineConfiguration::BudgetLine.index_executed })
      second_level_budget_lines_forecast = BudgetLine.all(where: { kind: BudgetLine::EXPENSE, level: 2, place: @site.place, year: @year, area_name: EconomicArea.area_name })

      main_budget_lines_summary = {}

      main_budget_lines_forecast.each do |budget_line|
        main_budget_lines_summary[budget_line.code] = {
          name: budget_line.name,
          budgeted_amount: budget_line.amount,
          path: budget_line.resource_path,
          descendants: second_level_budget_lines_forecast.select{ |bl| bl.parent_code == budget_line.code }.map{ |bl| { name: bl.name, path: bl.resource_path, budgeted_amount: bl.amount } }
        }
      end

      main_budget_lines_execution.each do |budget_line|
        executed_amount = budget_line.amount
        if main_budget_lines_summary[budget_line.code]
          budgeted_amount = main_budget_lines_summary[budget_line.code][:budgeted_amount]
          main_budget_lines_summary[budget_line.code].merge!(
            executed_amount: executed_amount,
            executed_percentage: (executed_amount*100 / budgeted_amount).to_i
          )
        end
      end
      main_budget_lines_summary.values
    end

    def budgets_execution_summary
      ine_code = @place.id

      year = @year
      previous_year = year - 1

      last_expenses_budgeted      = BudgetTotal.budgeted_for(ine_code, year)
      last_income_budgeted        = BudgetTotal.budgeted_for(ine_code, year, BudgetLine::INCOME)
      previous_expenses_budgeted  = BudgetTotal.budgeted_for(ine_code, previous_year)
      previous_income_budgeted    = BudgetTotal.budgeted_for(ine_code, previous_year, BudgetLine::INCOME)

      last_expenses_execution     = BudgetTotal.execution_for(ine_code, year)
      last_income_execution       = BudgetTotal.execution_for(ine_code, year, BudgetLine::INCOME)
      previous_expenses_execution = BudgetTotal.execution_for(ine_code, previous_year)
      previous_income_execution   = BudgetTotal.execution_for(ine_code, previous_year, BudgetLine::INCOME)

      {
        expenses_execution_percentage:          execution_percentage(last_expenses_budgeted, last_expenses_execution),
        expenses_previous_execution_percentage: execution_percentage(previous_expenses_budgeted, previous_expenses_execution),
        income_execution_percentage:            execution_percentage(last_income_budgeted, last_income_execution),
        income_previous_execution_percentage:   execution_percentage(previous_income_budgeted, previous_income_execution),
        previous_year: previous_year
      }
    end

    private

    def total_budget_per_inhabitant_query(year)
      SearchEngine.client.get(
        index: SearchEngineConfiguration::TotalBudget.index_forecast,
        type: SearchEngineConfiguration::TotalBudget.type,
        id: [@place.id, year, BudgetLine::EXPENSE].join('/')
      )
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      nil
    end

    def execution_percentage(budgeted_amount, executed_amount)
      if budgeted_amount && executed_amount && budgeted_amount != 0
        ((executed_amount * 100) / budgeted_amount).to_i
      end
    end

  end
end
