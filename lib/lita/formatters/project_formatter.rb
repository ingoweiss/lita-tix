module Lita
  module Formatters
    class ProjectFormatter < BaseFormatter

      alias_method :project, :item

      def summary
        lines = []

        if (defects = open_defects).any?
          lines << "---------------------------------------"
          lines << "DEFECTS (#{defects.size})"
          lines << "---------------------------------------"
          lines += defects.collect{ |defect| Lita::Formatters::DefectFormatter.new(defect, context).one_line_summary }
        end

        if (grouped_stories = group_by_drop_date(open_stories)).any?
          ['Late', 'Today', 'Tomorrow', 'Upcoming'].each do |header|
            next unless (stories = grouped_stories[header])
            lines << "---------------------------------------"
            lines << "#{header.upcase} (#{stories.size})"
            lines << "---------------------------------------"
            stories = limit(stories, 3) if header == 'Upcoming'
            lines += stories.collect{ |story| Lita::Formatters::StoryFormatter.new(story, context).one_line_summary }
          end
        end

        lines
      end

      private

      def open_defects
        pr = project
        rally_api.find(:defect) do
          equal :project, pr
          _or_ do
            equal :state, 'Submitted'
            equal :state, 'Open'
          end
        end.to_a
      end

      def open_stories
        pr = project
        stories = rally_api.find(:hierarchical_requirement) do
          equal     :project, pr
          equal     :release, nil
          not_equal :schedule_state, 'Accepted'
          not_equal :schedule_state, 'Client Accepted'
          not_equal :target_date, nil
        end.to_a
        stories.reject!{ |story| story.name.match(/\A\[unfinished\]/i) }
        stories
      end

      def group_by_drop_date(stories)
        infinity, negative_infinity = (1/0.0), -(1/0.0)
        grouped_stories = stories.group_by do |story|
          target_date = Date.parse(story.target_date)
          case target_date - Date.today
            when (negative_infinity..-1) then 'Late'
            when 0                       then 'Today'
            when 1                       then 'Tomorrow'
            when (2..infinity)           then 'Upcoming'
          end
        end
        grouped_stories.keys.each{ |header| grouped_stories[header] = sort_by_drop_date(grouped_stories[header]) }
        grouped_stories
      end

      def sort_by_drop_date(stories)
        stories.sort{ |a, b| Date.parse(a.target_date) <=> Date.parse(b.target_date) }
      end

      def limit(stories, number)
        stories_grouped_by_date = stories.group_by{ |s| Date.parse(s.target_date) }
        stories = []
        stories_grouped_by_date.keys.sort.each do |date|
          stories += stories_grouped_by_date[date]
          break if stories.size >= number
        end
        stories
      end

    end
  end
end



