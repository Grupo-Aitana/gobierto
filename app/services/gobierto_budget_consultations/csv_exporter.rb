# frozen_string_literal: true

module GobiertoBudgetConsultations
  class CsvExporter
    def self.export(consultation)
      attributes = %w[id age gender location question answer]

      CSV.generate(headers: true) do |csv|
        csv << attributes

        consultation.consultation_responses.sorted.each do |consultation_response|
          gender = begin
                     consultation_response.user_information['gender']
                   rescue
                     nil
                   end
          age = begin
                  ((Date.today - Date.parse(consultation_response.user_information['date_of_birth'])).to_i / 365.0).floor
                rescue
                  nil
                end
          location = begin
                       consultation_response.user_information['place']['raw_value']
                     rescue
                       nil
                     end

          consultation_response.consultation_items.each do |item|
            csv << [consultation_response.id, age, gender, location, item.item_title.strip, item.selected_option]
          end
        end
      end
    end
  end
end
