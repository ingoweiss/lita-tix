module Lita
  module Handlers
    class Rally < Handler

      DEFAULT_STORY_PATTERN  = /US\d+/i
      DEFAULT_DEFECT_PATTERN = /DE\d+/i
      DEFAULT_TASK_PATTERN   = /TA\d+/i

      on :loaded,            :define_routes
      on :unhandled_message, :unhandled_command_message

      def define_routes(payload={})
        Rally.route item_pattern,                :item_summary,        help: {"STORY/DEFECT/TASK_ID" => "Prints one line summary for STORY/DEFECT/TASK_ID"}, non_command_only: true
        Rally.route item_details_pattern,        :item_details,        help: {"STORY/DEFECT/TASK_ID" => "Prints details for STORY/DEFECT/TASK_ID"}, command: true
        Rally.route item_history_pattern,        :item_history,        help: {"STORY/DEFECT/TASK_ID history" => "Prints revision history for STORY/DEFECT/TASK_ID"}, command: true
        Rally.route item_comments_pattern,       :item_comments,       help: {"STORY/DEFECT_ID comments" => "Prints comments for STORY/DEFECT_ID"}, command: true
        Rally.route item_url_pattern,            :item_url,            help: {"STORY/DEFECT/TASK_ID url" => "Prints Rally URL of item"}, command: true
        Rally.route list_projects_pattern,       :list_projects,       help: {"projects" => "List projects"}, command: true
        unless config.read_only
          Rally.route update_item_state_pattern,   :update_item_state,   help: {"TASK/DEFECT_ID started/done/fixed/rejected" => "Updates state of TASK/DEFECT_ID"}, command: true
          Rally.route block_item_pattern,          :block_item,          help: {"STORY/DEFECT/TASK_ID blocked (by \"REASON\")" => "Marks item as blocked and adds optional blocked reason"}, command: true
          Rally.route unblock_item_pattern,        :unblock_item,        help: {"STORY/DEFECT/TASK_ID unblocked" => "Marks item as unblocked"}, command: true
          Rally.route mark_item_ready_pattern,     :mark_item_ready,     help: {"STORY_ID ready" => "Marks item as ready"}, command: true
          Rally.route mark_item_not_ready_pattern, :mark_item_not_ready, help: {"STORY_ID not ready" => "Marks item as not ready"}, command: true
          Rally.route delete_task_pattern,         :delete_task,         help: {"delete TASK_ID" => "Deletes task"}, command: true
          Rally.route assign_item_pattern,         :assign_item,         help: {"assign STORY/DEFECT/TASK_ID to @HIPCHAT_MENTION_NAME" => "Assign item to user by HipChat mention name"}, command: true
        end
        # TODO: The foloowing are out of place and should be extracted into a separate (project-specific?) plugin
        Rally.route project_summary_pattern,     :project_summary,     command: true
      end

      config :username, type: String, required: true
      config :password, type: String, required: true
      config :scope do
        config :workspace, type: String
        config :projects, type: Array, default: []
        config :creation_date do
          config :greater_than, type: String
        end
      end
      config :patterns do
        config :story,  type: Regexp
        config :defect, type: Regexp
      end
      config :state_field do
        config :story,  type: Symbol
        config :defect, type: Symbol
      end
      config :display_name, type: Symbol, default: :hipchat_name do
        validate do |value|
          "Display name can be either :first_name, :full_name or :hipchat_name" unless [:first_name, :full_name, :hipchat_name].include?(value)
        end
      end
      config :not_found_messages, types: [TrueClass, FalseClass], default: true
      config :read_only, types: [TrueClass, FalseClass], default: false
      config :multiple_items_limit, type: Integer, default: 10

      def item_summary(response)
        lines = []
        item_ids(response).each do |item_id|
          if (item = find_item(item_id))
            lines << item_formatter(item, context).one_line_summary(:referred_to_by => item_id)
          end
        end
        if lines.any?
          response.reply join_lines(lines)
        else
          response.reply(random_not_found_message) unless !config.not_found_messages
        end
      end

      def item_details(response)
        multiple_item_response(response) do |item_id|
          if (item = find_item(item_id))
            join_lines item_formatter(item, context).details(:referred_to_by => item_id)
          else
            not_found_message(item_id)
          end
        end
      end

      def item_history(response)
        single_item_response(response) do |item_id|
          if (item = find_item(item_id))
            join_lines item_formatter(item, context).history
          else
            not_found_message(item_id)
          end
        end
      end

      def item_comments(response)
        single_item_response(response) do |item_id|
          if (item = find_item(item_id))
            if item.discussion
              join_lines item_formatter(item, context).comments
            else
              t('no_comments')
            end
          else
            not_found_message(item_id)
          end
        end
      end

      def item_url(response)
        multiple_item_response(response) do |item_id|
          if (item = find_item(item_id))
            url_for(item)
          else
            not_found_message(item_id)
          end
        end
      end

      def update_item_state(response)
        command = second_capture_group(response)
        multiple_item_response(response) do |item_id|
          if (item = find_item(item_id))
            item_type = item_type_for(item_id)
            if (state_update = state_update_for_update_command(item_type, command))
              begin
                item.update(state_update)
                state_update.each do |field, value|
                  comment_item(item, t('update_item_state_log', field: display_name_for_rally_field(field), value: value, user: response.user.name, bot: robot.name))
                end
                item_formatter(item, context).one_line_summary(:referred_to_by => item_id)
              rescue
                t('could_not_update', item: item_id)
              end
            else
              invalid_item_state_update_message(item_id, item_type, command)
            end
          else
            not_found_message(item_id)
          end
        end
      end

      def block_item(response)
        blocked_reason = second_capture_group(response)
        multiple_item_response(response) do |item_id|
          if (item = find_item(item_id))
            item.update(:blocked => true, :blocked_reason => blocked_reason)
            comment_item(item, t('block_item_log', user: response.user.name, bot: robot.name))
            item_formatter(item, context).one_line_summary(:referred_to_by => item_id)
          else
            not_found_message(item_id)
          end
        end
      end

      def unblock_item(response)
        multiple_item_response(response) do |item_id|
          if (item = find_item(item_id))
            item.update(:blocked => false)
            comment_item(item, t('unblock_item_log', user: response.user.name, bot: robot.name))
            item_formatter(item, context).one_line_summary(:referred_to_by => item_id)
          else
            not_found_message(item_id)
          end
        end
      end

      def mark_item_ready(response)
        multiple_item_response(response) do |item_id|
          if (item = find_item(item_id))
            item.update(:ready => true)
            comment_item(item, t('mark_item_ready_log', user: response.user.name, bot: robot.name))
            item_formatter(item, context).one_line_summary(:referred_to_by => item_id)
          else
            not_found_message(item_id)
          end
        end
      end

      def mark_item_not_ready(response)
        multiple_item_response(response) do |item_id|
          if (item = find_item(item_id))
            item.update(:ready => false)
            comment_item(item, t('mark_item_not_ready_log', user: response.user.name, bot: robot.name))
            item_formatter(item, context).one_line_summary(:referred_to_by => item_id)
          else
            not_found_message(item_id)
          end
        end
      end

      def delete_task(response)
        multiple_item_response(response) do |item_id|
          if (item = find_item(item_id))
            item.delete
            t('delete_task_confirmation_message', task_id: item_id)
          else
            not_found_message(item_id)
          end
        end
      end

      def assign_item(response)
        user_id = second_capture_group(response)
        user_id = response.user.name if user_id == 'me' # TODO: use rally.user instead?
        unless (user = find_user(user_id))
          response.reply t('could_not_find', item: user_id)
          return
        end
        multiple_item_response(response) do |item_id|
          if (item = find_item(item_id))
            item.update(:owner => user)
            comment_item(item, t('assign_item_log', user: response.user.name, owner: user.name, bot: robot.name))
            item_formatter(item, context).one_line_summary(:referred_to_by => item_id)
          else
            not_found_message(item_id)
          end
        end
      end

      def list_projects(response)
        response.reply join_lines(projects.collect(&:name))
      end

      def project_summary(response)
        single_project_only(response) do
          ask_for_some_patience(response)
          response.reply join_lines(Lita::Formatters::ProjectFormatter.new(projects.first, context).summary)
        end
      end

      def unhandled_command_message(payload)
        message = payload[:message]
        if message.command?
          message_type = (message.body.end_with?('?') ? 'question' : 'command')
          message.reply t("unhandled_#{message_type}_message")
        end
      end


      private

      def single_match(response)
        if response.matches.one?
          response.matches.first
        else
          # TODO: handle this
          # should not get here
        end
      end

      def first_capture_group(response)
        match = single_match(response)
        match.is_a?(Array) ? match[0] : match
      end

      def second_capture_group(response)
        match = single_match(response)
        match.is_a?(Array) ? match[1] : nil
      end

      def multiple_item_response(response, &block)
        item_ids = multiple_item_ids(first_capture_group(response))
        if (item_ids.size > config.multiple_items_limit)
          response.reply(t('exceeds_multiple_items_limit', limit: config.multiple_items_limit))
        else
          lines = []
          item_ids.each do |item_id|
            lines << (yield item_id)
          end
          response.reply join_lines(lines)
        end
      end

      def single_item_response(response, &block)
        item_id = first_capture_group(response).upcase
        response.reply (yield item_id)
      end

      def join_lines(lines)
        lines.join("\n")
      end

      def item_ids(response)
        response.matches.flatten.collect(&:upcase).uniq
      end

      def multiple_item_ids(item_ids)
        item_ids.split.map(&:upcase).uniq[0..config.multiple_items_limit]
      end

      def find_items(item_id)
        item_type = item_type_for(item_id)
        if item_type == :task
          items = find_items_by_type_and_id(item_type, item_id)
        else
          if (configured_pattern = configured_pattern_for(item_type))
            if item_id.match(configured_pattern)
              items = find_items_by_type_and_id_in_name(item_type, item_id)
              if items.empty? && item_id.match(default_pattern_for(item_type))
                items = find_items_by_type_and_id(item_type, item_id)
              end
            elsif item_id.match(default_pattern_for(item_type))
              items = find_items_by_type_and_id(item_type, item_id)
            end
          else
            items = find_items_by_type_and_id(item_type, item_id)
          end
        end
        items
      end

      def find_item(item_id)
        find_items(item_id).first
      end

      def find_items_by_type_and_id_in_name(item_type, item_id)
        log.debug("Searching for #{item_type} with \"#{item_id}\" in name")
        this_projects = projects
        this_config = config
        items = rally_api.find(item_type, *search_args) do
          _or_ do
            this_projects.each{ |project| equal :project, project }
          end
          if date = this_config.scope.creation_date.greater_than
            greater_than :creation_date, date
          end
          contains :name, item_id
        end
        # 'contains' finds partial matches ('US1234' when searching for 'US1'), so we need to filter some more:
        items.select { |item| item.name.match(/\b#{item_id}\b/i) }
      end

      def find_items_by_type_and_id(item_type, item_id)
        log.debug("Searching for #{item_type} with id \"#{item_id}\"")
        this_projects = projects
        this_config = config
        rally_api.find(item_type, *search_args) do
          _or_ do
            this_projects.each{ |project| equal :project, project }
          end
          if date = this_config.scope.creation_date.greater_than
            greater_than :creation_date, date
          end
          equal :formatted_i_d, item_id
        end
      end

      def find_user(user_id)
        case user_id
        when /\A#{hipchat_name_pattern}\Z/  then find_user_by_hipchat_mention_name(user_id)
        when /\A#{full_name_pattern}\Z/     then find_user_by_full_name(user_id)
        when /\A#{email_address_pattern}\Z/ then find_user_by_email_address(user_id)
        end
      end

      def find_user_by_hipchat_mention_name(mention_name)
        mention_name.gsub!(/\A@/, '')
        roster_item_for_user = roster.items.values.find{ |item| item.attributes['mention_name'] == mention_name }
        roster_item_for_user && find_user_by_email_address(roster_item_for_user.attributes['email'])
      end

      def find_user_by_full_name(full_name)
        roster_item_for_user = roster.items.values.find{ |item| item.attributes['name'] == full_name }
        roster_item_for_user && find_user_by_email_address(roster_item_for_user.attributes['email'])
      end

      def find_user_by_email_address(email_address)
        rally_api.find(:user, *search_args){ equal :email_address, email_address }.first
      end

      def projects
        @project ||= config.scope.projects.collect do |project_name|
          log.debug("Searching for project \"#{project_name}\"")
          rally_api.find(:project, *search_args) { equal :name, project_name }.first
        end
      end

      def workspace
        return unless config.scope.workspace
        @workspace ||= rally_api.user.subscription.workspaces.find{|ws| ws.name == config.scope.workspace }
      end

      def search_args
        workspace ? [{ :workspace => workspace }] : []
      end

      def url_for(item)
        item_type = {
          'HierarchicalRequirement' => :userstory,
          'Defect'                  => :defect,
          'Task'                    => :task
        }[item.type]
        rally_api.base_url.sub(/slm\Z/, '') + "#/detail/#{item_type}/" + item.object_i_d
      end

      def item_type_for(item_id)
        case item_id
          when story_pattern  then :hierarchical_requirement
          when defect_pattern then :defect
          when task_pattern   then :task
        end
      end

      UPDATE_COMMANDS = {
        [:task,   'started']                     => {:state => 'In-Progress'},
        [:task,   'done']                        => {:state => 'Completed'},
        [:defect, 'started']                     => {:state => 'Open'},
        [:defect, 'fixed']                       => {:state => 'Fixed'},
        [:defect, 'rejected']                    => {:state => 'Rejected'},
        [:hierarchical_requirement, 'accepted']  => {:schedule_state => 'Accepted'}
      }

      def state_update_for_update_command(item_type, command)
        UPDATE_COMMANDS[[item_type, command]]
      end

      def update_commands_for_type(item_type)
        UPDATE_COMMANDS.keys.find_all{|t, c| t == item_type}.collect{ |t, c| c }
      end

      def invalid_item_state_update_message(item_id, item_type, command)
        item_type_for_display = { :task => 'task', :defect => 'defect', :hierarchical_requirement => 'story' }[item_type]
        update_commands = update_commands_for_type(item_type)
        t('invalid_item_state_update',
          item_id:         item_id,
          item_type:       item_type_for_display,
          valid_commands:  [update_commands[0..-2].join(', '), update_commands[-1]].reject(&:empty?).join(' or '),
          invalid_command: command
        )
      end

      def comment_item(item, comment)
        rally_api.create(
          :conversation_post,
          :artifact => item,
          :text     => comment,
          :user     => rally_api.user
        )
      end

      def random_not_found_message
        t('not_found_messages').sample
      end

      def not_found_message(item_id)
        t('could_not_find', item: item_id)
      end

      def ask_for_some_patience(response)
        response.reply(t('working'))
      end

      def rally_api
        @rally_api ||= RallyRestAPI.new(:username => config.username, :password => config.password, :version => '1.38')
      end

      def roster
        # FIXME: Hack!!
        return unless (adapter = robot.instance_variable_get(:@adapter))
        return unless adapter.respond_to?(:connector)
        adapter.connector.roster
      end

      def context
        { :rally_api => rally_api, :robot => robot, :roster => roster }
      end

      def item_formatter(item, context)
        Lita::Formatters::BaseFormatter.formatter(item, context)
      end

      def configured_pattern_for(item_type)
        { :hierarchical_requirement => config.patterns.story, :defect => config.patterns.defect }[item_type]
      end

      def default_pattern_for(item_type)
        { :hierarchical_requirement => DEFAULT_STORY_PATTERN, :defect => DEFAULT_DEFECT_PATTERN }[item_type]
      end

      def defect_pattern
        config.patterns.defect ? Regexp.union(config.patterns.defect, DEFAULT_DEFECT_PATTERN) : DEFAULT_DEFECT_PATTERN
      end

      def story_pattern
        config.patterns.story ? Regexp.union(config.patterns.story, DEFAULT_STORY_PATTERN) : DEFAULT_STORY_PATTERN
      end

      def task_pattern
        DEFAULT_TASK_PATTERN
      end

      def item_pattern
        /\b#{Regexp.union([story_pattern, defect_pattern, task_pattern])}\b/
      end

      def hipchat_name_pattern
        /@[A-Za-z]+/
      end

      def email_address_pattern
        /[A-Za-z0-9.]+@[A-Za-z0-9.]+/
      end

      def full_name_pattern
        /[A-Za-z]+ [A-Za-z]+/
      end

      def item_details_pattern
        /\A#{multiple_pattern(item_pattern)}\Z/
      end

      def item_history_pattern
        /\A(#{item_pattern}) history\Z/
      end

      def item_comments_pattern
        /\A(#{item_pattern}) comments\Z/
      end

      def item_url_pattern
        /\A(#{multiple_pattern(item_pattern)}) url\Z/
      end

      def update_item_state_pattern
        /\A(#{multiple_pattern(item_pattern)}) (started|done|fixed|rejected|accepted)\Z/
      end

      def block_item_pattern
        /\A(#{multiple_pattern(item_pattern)}) blocked(?: by "([^"]+)")?\Z/
      end

      def unblock_item_pattern
        /\A(#{multiple_pattern(item_pattern)}) unblocked\Z/
      end

      def mark_item_ready_pattern
        /\A(#{multiple_pattern(story_pattern)}) ready\Z/
      end

      def mark_item_not_ready_pattern
        /\A(#{multiple_pattern(story_pattern)}) not ready\Z/
      end

      def delete_task_pattern
        /\Adelete (#{multiple_pattern(task_pattern)})\Z/
      end

      def assign_item_pattern
        /\Aassign (#{multiple_pattern(item_pattern)}) to (#{Regexp.union([hipchat_name_pattern, full_name_pattern, email_address_pattern, /me/])}) ?\Z/
      end

      def list_projects_pattern
        /\Aprojects\Z/i
      end

      def project_summary_pattern
        /\Atoday\Z/i
      end

      def project_defects_pattern
        /\Adefects\Z/i
      end

      def multiple_projects?
        config.scope.projects.size > 1
      end

      def single_project_only(response, &block)
        if multiple_projects?
          response.reply t('unsupported_for_multiple_projects_message')
        else
          yield
        end
      end

      def multiple_pattern(pattern)
        /#{pattern}(?: #{pattern})*/
      end

      def display_name_for_rally_field(rally_field_name)
        rally_field_name.to_s.split('_').collect(&:capitalize).join(' ')
      end

    end

    Lita.register_handler(Rally)
  end
end
