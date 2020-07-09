module Lita
  module Formatters
    class TaskFormatter < BaseFormatter

      alias_method :task, :item

      def one_line_summary(options={})
        options[:hide_parent] ? super(options) : "[#{display_id(task.work_product)}] → #{super(options)}"
      end

      def details(options={})
        lines = []
        if task.work_product
          lines << Lita::Formatters::StoryFormatter.new(task.work_product, context).one_line_summary
          lines << indent(one_line_summary(:hide_parent => true))
        else
          lines << one_line_summary
        end
        lines
      end

      def configured_item_pattern
        nil
      end

    end
  end
end
