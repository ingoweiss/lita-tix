require "lita-rally"
require "lita/rspec"
Lita.version_3_compatibility_mode = false
require "timecop"
require 'byebug'

def mock_story(attributes={})
  double({
    :formatted_i_d  => 'US123',
    :name           => 'User places an order',
    :owner          => mock_user,
    :type           => 'HierarchicalRequirement',
    :schedule_state => 'Accepted',
    :ready          => 'false',
    :blocked        => 'false',
    :target_date    => '2014-09-01',
    :release        => nil,
    :tasks          => [],
    :creation_date  => '2015-01-01',
    :plan_estimate  => '5.0',
    :tags           => []
  }.merge(attributes))
end

def mock_defect(attributes={})
  double({
    :formatted_i_d  => 'DE123',
    :name           => 'Error when placing order',
    :owner          => mock_user,
    :type           => 'Defect',
    :state          => 'Open',
    :ready          => 'false',
    :blocked        => 'false',
    :release        => nil,
    :requirement    => nil,
    :creation_date  => '2015-01-01',
    :tags           => []
  }.merge(attributes))
end

def mock_task(attributes={})
  double({
    :formatted_i_d  => 'TA123',
    :name           => 'Code review',
    :type           => 'Task',
    :state          => 'Defined',
    :ready          => 'false',
    :blocked        => 'false',
    :owner          => mock_user,
    :work_product   => nil,
    :tags           => [],
    :work_product   => mock_story
  }.merge(attributes))
end

def mock_user(attributes={})
  double({
    :first_name => 'Joe',
    :last_name => 'Simmons',
    :email_address => 'joe.simmons@email.com'
  }.merge(attributes))
end

def mock_roster(roster_items=[])
  roster_items << mock_roster_item if roster_items.empty?
  roster_items_hash = roster_items.inject({}) do |ri_hash, ri_attributes|
    ri_hash[ri_attributes['email']] = double(:attributes => ri_attributes)
    ri_hash
  end
  double(:items => roster_items_hash)
end

def mock_roster_item(attributes={})
  {
    'email' => 'joe.simmons@email.com',
    'mention_name' => 'joe'
  }.merge(attributes)
end

def stub_find(items=[])
  api = double(:find => items)
  allow(RallyRestAPI).to receive(:new).and_return(api)
end

def configure_patterns(patterns)
  patterns = {:story => nil, :defect => nil}.merge(patterns)
  allow(subject.config).to receive(:patterns).and_return(double(patterns))
  described_class.routes.clear
  subject.define_routes
end

def lines(reply)
  reply.split("\n")
end

RSpec.configure do |config|
  config.before do
    registry.register_hook(:validate_route, Lita::Extensions::NonCommandOnly)
  end
end
