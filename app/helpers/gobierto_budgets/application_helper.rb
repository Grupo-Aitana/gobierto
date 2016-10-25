module GobiertoBudgets
  module ApplicationHelper

    def current_parameters_with_year(year)
      params.except(:host, :port, :protocol).merge(year: year).permit!
    end

    def sign(v1, v2 = nil)
      return 'sign-neutral' if v1.blank? || v2.blank?
      diff = v1 - v2
      if diff > 0
        'sign-up'
      elsif diff < 0
        'sign-down'
      else
        'sign-neutral'
      end
    rescue
      'sign-neutral'
    end

    def format_currency(n, absolute_value = false)
      return nil if n.blank?
      n = n.abs if absolute_value

      if n.abs > 1_000_000
        "#{helpers.number_with_precision(n.to_f / 1_000_000.to_f, precision: 1, strip_insignificant_zeros: true)}M€"
      else
        helpers.number_to_currency(n, precision: 1, strip_insignificant_zeros: true)
      end
    end

    def delta_percentage(current_year_value, old_value)
      number_with_precision(((current_year_value.to_f - old_value.to_f)/old_value.to_f) * 100, precision: 2).to_s + "%"
    end

    def percentage_of_total(value, total)
      number_with_precision((value.to_f / total.to_f) * 100, precision: 2) + '%'
    end

    def area_class(area, kind)
      return GobiertoBudgets::FunctionalArea if (area == 'functional' && %{income i}.exclude?(kind.downcase))
      GobiertoBudgets::EconomicArea
    end

    def budget_line_denomination(area, code, kind, capped = -1)
      area = area_class area, kind
      if area.all_items[kind][code].nil?
        res = " - "
      else
        res = area.all_items[kind][code][0..capped]
        res += "..." if capped < res.length && capped > -1
      end
      res
    end

    def budget_line_description(area_name, code, kind)
      area = area_class area_name, kind
      description = area.all_descriptions[kind][code.to_s]
      name = area.all_items[kind][code]
      if description != name
        return description
      else
        kind_what = kind == 'I' ? 'ingresos' : 'gastos'

        "Esta partida comprende los #{kind_what} en #{description.downcase}. Si quieres saber más sobre esta partida puedes consultar la partida padre: #{link_to(budget_line_denomination(area_name, code[0..-2], kind), gobierto_sites_budget_line_path(code[0..-2], params[:year], area_name, kind))}"
      end
    end

    def kind_literal(kind, plural = true)
      if kind == 'I'
        plural ? 'ingresos' : 'ingreso'
      else
        plural ? 'gastos' : 'gasto'
      end
    end

    def data_attributes
      attrs = []
      if @place
        attrs << %Q{data-track-url="#{gobierto_sites_budgets_path(@year || GobiertoBudgets::SearchEngineConfiguration::Year.last)}"}
        attrs << %Q{data-place-slug="#{@place.slug}"}
        attrs << %Q{data-place-name="#{@place.name}"}
      end
      if action_name == 'compare' and controller_name == 'places'
        attrs << %Q{data-comparison-name="#{@places.map{|p| p.name }.join(' + ')}"}
        attrs << %Q{data-comparison-track-url="#{request.path}"}
        attrs << %Q{data-comparison-slug="#{params[:slug_list]}"}
      end
      attrs << %Q{data-year="#{@year || GobiertoBudgets::SearchEngineConfiguration::Year.last}"}
      attrs << %Q{data-kind="#{@kind || 'expense'}"}
      attrs << %Q{data-area="#{@area_name || 'economic'}"}
      attrs << %Q{data-action="#{action_name}"}
      attrs.join(' ').html_safe
    end

    def place_name(ine_code)
      INE::Places::Place.find(ine_code).try(:name)
    end

    def parent_code(code)
      if code.present?
        if code.include?('-')
          code.split('-').first
        else
          code[0..-2]
        end
      end
    end
  end
end
