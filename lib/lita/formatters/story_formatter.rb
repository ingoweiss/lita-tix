module Lita
  module Formatters
    class StoryFormatter < BaseFormatter

      alias_method :story, :item

      def details(options={})
        lines = [one_line_summary(options)]
        if story.tasks
          story.tasks.each do |task|
            lines << indent(Lita::Formatters::TaskFormatter.new(task, context).one_line_summary(:hide_parent => true))
          end
        else
          lines << I18n.translate(:'lita.formatters.story.no_tasks')
        end
        lines
      end

      private

      def info
        [size, owner, state, blocker, schedule, tags]
      end

      def state
        @state ||= story_state.downcase + (item.ready == 'true' ? ' and ready' : '')
      end

      def story_state
        configured_state_field ? story.elements[configured_state_field] : story.schedule_state
      end

      def size
        story.plan_estimate && I18n.translate(:'lita.formatters.story.size', count: story.plan_estimate.to_i)
      end

      def schedule
        return nil unless drop_date
        @schedule ||= if story.release
          "#{story.schedule_state == 'Client Accepted' ? 'dropped' : 'dropping/dropped'} with release #{story.release.name}"
        else
          if drop_date == Date.today
            I18n.translate(:'lita.formatters.story.schedule.today')
          elsif drop_date == (Date.today + 1)
            I18n.translate(:'lita.formatters.story.schedule.tomorrow')
          elsif drop_date >  (Date.today + 1)
            I18n.translate(:'lita.formatters.story.schedule.future', date: formatted_drop_date)
          elsif drop_date == (Date.today - 1)
            I18n.translate(:'lita.formatters.story.schedule.yesterday')
          elsif drop_date <  (Date.today - 1)
            I18n.translate(:'lita.formatters.story.schedule.past', date: formatted_drop_date)
          end
        end
      end

      def drop_date
        @drop_date ||= (story.target_date && Date.parse(story.target_date))
      end

      def formatted_drop_date
        @formatted_drop_date ||= drop_date.strftime('%b %-d')
      end

      def configured_item_pattern
        robot.config.handlers.rally.patterns.story
      end

      def configured_state_field
        robot.config.handlers.rally.state_field.story
      end

    end
  end
end
