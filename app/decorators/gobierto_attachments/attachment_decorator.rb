# frozen_string_literal: true

module GobiertoAttachments
  class AttachmentDecorator < BaseDecorator
    DEFAULT_TEMPLATE = ->(sub_template) { "gobierto_attachments/attachment_documents/templates/#{sub_template}" }
    CONTEXT_CONFIGURATION = {
      "GobiertoParticipation::Process" => { template: ->(sub_template) { "gobierto_participation/processes/attachments/templates/#{sub_template}" },
                                            layout: 'gobierto_participation/layouts/application',
                                            module: 'gobierto_participation' },
      "GobiertoParticipation"          => { template: ->(sub_template) { "gobierto_participation/attachments/templates/#{sub_template}" },
                                            layout: 'gobierto_participation/layouts/application',
                                            module: 'gobierto_participation' },
      :default                         => { template: DEFAULT_TEMPLATE,
                                            layout: nil,
                                            module: nil },
    }

    def initialize(attachment, context = nil, item_type = nil)
      @object = attachment
      @context = context || attachment.collection.container_type
      @item_type = item_type || attachment.collection.item_type
      @layout_configuration ||= OpenStruct.new(CONTEXT_CONFIGURATION[@context] || CONTEXT_CONFIGURATION[:default])
    end

    def template
      @template ||= @layout_configuration.template.call(sub_template)
    end

    def layout
      @layout ||= @layout_configuration.layout
    end

    def module
      @module ||= @layout_configuration.module
    end

    private

    def sub_template
      @item_type.demodulize.underscore
    end
  end
end