module Lita
  module Formatters
    class DefectFormatter < BaseFormatter

      alias_method :defect, :item

      def one_line_summary(options={})
        (options[:hide_parent] || !defect.requirement) ? super(options) : "[#{display_id(defect.requirement)}] → #{super(options)}"
      end

      def details(options={})
        lines = []
        if defect.requirement
          lines << Lita::Formatters::StoryFormatter.new(defect.requirement, context).one_line_summary
          lines << indent(one_line_summary(:hide_parent => true))
        else
          lines << one_line_summary(options)
        end
        lines
      end

      private

      def state
        @state ||= if (defect.state == 'Fixed' && defect.release)
          I18n.translate(:'lita.formatters.defect.state.fixed_and_released', release: defect.release)
        elsif (defect.state == 'Closed' && defect.release)
          I18n.translate(:'lita.formatters.defect.state.fixed_and_released_and_closed', release: defect.release)
        else
          defect.state.downcase
        end
      end

      def configured_item_pattern
        robot.config.handlers.rally.patterns.defect
      end

    end
  end
end
