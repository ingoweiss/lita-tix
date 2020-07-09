# lita-rally

A Lita (lita.io) plugin for adding the capability to interact with Rally to chat bots

## Installation

1. Install the 'lita-rally' gem
2. Add lita-rally to your Lita instance's Gemfile:

``` ruby
gem "lita-rally"
```

## Required Configuration

``` ruby
config.handlers.rally.username = "[Rally Username]"
config.handlers.rally.password = "[Rally Password]"
config.handlers.rally.scope.projects = ["[Name of Rally Project 1]", ...]
```

## Optional Configuration

``` ruby
config.handlers.rally.scope.creation_date.greater_than = "[Date]" # format '2015-01-01']
config.handlers.rally.patterns.story = [Regex]                    # defaults to /US\d+/i
config.handlers.rally.patterns.defect = [Regex]                   # defaults to /DE\d+/i
config.handlers.rally.state_field.story = [Symbol]                # custom story state field such as :custom_kanban_state
config.handlers.rally.display_name = [Symbol]                     # :hipchat_name (default), :full_name or :first_name
config.handlers.rally.not_found_messages = [true/false]           # defaults to true
config.handlers.rally.read_only = [true/false]                    # defaults to false
config.handlers.rally.:multiple_items_limit = [Integer]           # defaults to 10
config.handlers.rally.scope.workspace = "[Workspace]"             # if not specified, user's default workspace is used
```

## Commands

``` bash
@bot US123
@bot DE123 started
@bot DE123 fixed
@bot DE123 rejected
@bot TA123 started
@bot TA123 done
@bot US123 accepted
@bot US123 blocked
@bot US123 blocked by "Coffe machine broken"
@bot US123 unblocked
@bot US123 ready
@bot US123 not ready
@bot US123 history
@bot US123 comments
@bot US123 url
@bot delete TA123
@bot assign TA123 to @joe
@bot assign TA123 to Jane Jacobs
@bot assign TA123 to jane.jacobs@example.com
@bot assign TA123 to me
@bot help
```