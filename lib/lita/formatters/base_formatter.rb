module Lita
  module Formatters
    class BaseFormatter

      attr_reader :item, :context

      def initialize(item, context={})
        @item = item
        @context = context
      end

      def one_line_summary(options={})
        summary = "#{item.name} (#{info.compact.join(', ')})"
        show_rally_id?(item, options) ? "[#{item.formatted_i_d}] #{summary}" : summary
      end

      def history
        item.revision_history.revisions.collect{ |revision| formatted_revision(revision) }
      end

      def formatted_revision(revision)
        I18n.translate(:'lita.formatters.base.revision',
          timestamp: DateTime.parse(revision.creation_date).strftime('%Y-%m-%d %I:%M%p'),
          user: revision.user.first_name,
          description: revision.description
        )
      end

      def comments
        item.discussion.collect{ |r| "[#{DateTime.parse(r.creation_date).strftime('%Y-%m-%d %I:%M%p')} by #{r.user.first_name}] #{r.text}"}
      end

      def self.formatter(item, context={})
        case item.type
          when 'HierarchicalRequirement' then StoryFormatter.new(item, context)
          when 'Defect'                  then DefectFormatter.new(item, context)
          when 'Task'                    then TaskFormatter.new(item, context)
        end
      end

      private

      # The following logic makes a couple of assumptions:
      # 1) if a story pattern is defined, there will always be only one matching story ID in a story's name, and that's that story's ID
      def show_rally_id?(item, options)
        id, pattern = options[:referred_to_by], configured_item_pattern_for(item)
        return true if !pattern
        if id
          if item.name.match(/\b#{id}\b/)
            return false
          else
            return true
          end
        end
        return false if item.name.match(/\b#{pattern}\b/)
        return true
      end

      def info
        [owner, state, blocker, tags]
      end

      def owner
        @owner ||= (item.owner ? display_name(item.owner) : nil)
      end

      def state
        @state ||= item.state.downcase
      end

      def blocker
        return @blocker if @blocker
        if item.blocked == 'true'
          @blocker =  'blocked'
          @blocker << " by \"#{item.blocked_reason}\"" if item.blocked_reason
        end
        @blocker
      end

      def tags
        if item.tags.nil? || item.tags.empty?
          nil
        else
          item.tags.collect(&:name).map(&:downcase).join(', ')
        end
      end

      def display_name(user)
        case context[:robot].config.handlers.rally.display_name
        when :hipchat_name then hipchat_name(user) || full_name(user) # fall back to full name if an owner has since left the team
        when :first_name then first_name(user)
        when :full_name then full_name(user)
        end
      end

      def first_name(user)
        user.first_name
      end

      def last_name(user)
        user.last_name
      end

      def full_name(user)
        [first_name(user), last_name(user)].join(' ')
      end

      def hipchat_name(user)
        roster_item_for_user = roster.items.values.find{ |item| item.attributes['email'] == user.email_address }
        roster_item_for_user && "@#{roster_item_for_user.attributes['mention_name']}"
      end

      def robot
        context[:robot]
      end

      def rally_api
        context[:rally_api]
      end

      def roster
        context[:roster]
      end

      def indent(line)
        '↳ ' + line
      end

      def display_id(story_or_defect)
        pattern = configured_item_pattern_for(story_or_defect)
        (pattern && story_or_defect.name.match(pattern)) || story_or_defect.formatted_i_d
      end

      def configured_item_pattern_for(item)
        configured_patterns = robot.config.handlers.rally.patterns
        case item.type
        when 'HierarchicalRequirement'
          configured_patterns.story
        when 'Defect'
          configured_patterns.defect
        else
          nil
        end
      end

    end
  end
end
