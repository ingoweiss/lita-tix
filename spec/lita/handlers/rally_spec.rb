require "spec_helper"

describe Lita::Handlers::Rally, lita_handler: true do

  before(:each) do
    described_class.routes.clear
    allow_any_instance_of(described_class).to receive(:roster).and_return(mock_roster)
  end

  describe 'routing' do

    it { is_expected.to route("How far along is US123?").to(:item_summary)  }
    it { is_expected.to route("How far along is us123?").to(:item_summary)  }
    it { is_expected.to route("How far along is DE123?").to(:item_summary)  }
    it { is_expected.to route("How far along is de123?").to(:item_summary)  }
    it { is_expected.to route("How far along is TA123?").to(:item_summary)  }
    it { is_expected.to route("How far along is ta123?").to(:item_summary)  }
    it { is_expected.to_not route("Did you test BETA1?").to(:item_summary)  }

    it { is_expected.to route_command("US123").to(:item_details) }
    it { is_expected.to route_command("us123").to(:item_details) }
    it { is_expected.to route_command("DE123").to(:item_details) }
    it { is_expected.to route_command("de123").to(:item_details) }
    it { is_expected.to route_command("TA123").to(:item_details) }
    it { is_expected.to route_command("ta123").to(:item_details) }

    it { is_expected.to route_command("US123 history").to(:item_history) }
    it { is_expected.to route_command("us123 history").to(:item_history) }
    it { is_expected.to route_command("DE123 history").to(:item_history) }
    it { is_expected.to route_command("de123 history").to(:item_history) }
    it { is_expected.to route_command("TA123 history").to(:item_history) }
    it { is_expected.to route_command("ta123 history").to(:item_history) }

    it { is_expected.to route_command("US123 comments").to(:item_comments) }
    it { is_expected.to route_command("us123 comments").to(:item_comments) }
    it { is_expected.to route_command("DE123 comments").to(:item_comments) }
    it { is_expected.to route_command("de123 comments").to(:item_comments) }

    it { is_expected.to route_command("US123 url").to(:item_url) }
    it { is_expected.to route_command("us123 url").to(:item_url) }
    it { is_expected.to route_command("DE123 url").to(:item_url) }
    it { is_expected.to route_command("de123 url").to(:item_url) }
    it { is_expected.to route_command("TA123 url").to(:item_url) }
    it { is_expected.to route_command("ta123 url").to(:item_url) }

    it { is_expected.to route_command("TA123 started").to(:update_item_state) }
    it { is_expected.to route_command("ta123 started").to(:update_item_state) }
    it { is_expected.to route_command("TA123 done").to(:update_item_state) }
    it { is_expected.to route_command("TA123 TA345 TA456 done").to(:update_item_state) }
    it { is_expected.to route_command("ta123 done").to(:update_item_state) }
    it { is_expected.to route_command("DE123 fixed").to(:update_item_state) }
    it { is_expected.to route_command("de123 fixed").to(:update_item_state) }
    it { is_expected.to route_command("DE123 rejected").to(:update_item_state) }
    it { is_expected.to route_command("de123 rejected").to(:update_item_state) }
    it { is_expected.to route_command("US123 accepted").to(:update_item_state) }
    it { is_expected.to route_command("us123 accepted").to(:update_item_state) }

    it { is_expected.to route_command("TA123 blocked").to(:block_item) }
    it { is_expected.to route_command("TA123 blocked by \"Crucible down\"").to(:block_item) }
    it { is_expected.to route_command("US123 blocked").to(:block_item) }
    it { is_expected.to route_command("US123 blocked by \"Crucible down\"").to(:block_item) }
    it { is_expected.to route_command("DE123 blocked").to(:block_item) }
    it { is_expected.to route_command("DE123 blocked by \"Crucible down\"").to(:block_item) }

    it { is_expected.to route_command("TA123 unblocked").to(:unblock_item) }
    it { is_expected.to route_command("US123 unblocked").to(:unblock_item) }
    it { is_expected.to route_command("DE123 unblocked").to(:unblock_item) }

    it { is_expected.to route_command("US123 ready").to(:mark_item_ready) }
    it { is_expected.to route_command("US123 not ready").to(:mark_item_not_ready) }

    it { is_expected.to route_command("delete TA123").to(:delete_task) }
    it { is_expected.to_not route_command("delete US123").to(:delete_task) }
    it { is_expected.to_not route_command("delete DE123").to(:delete_task) }

    it { is_expected.to route_command("assign US123 to @joe").to(:assign_item) }
    it { is_expected.to route_command("assign US123 to @joe ").to(:assign_item) } # because HipChat adds a space
    it { is_expected.to route_command("assign DE123 to @joe").to(:assign_item) }
    it { is_expected.to route_command("assign TA123 to @joe").to(:assign_item) }
    it { is_expected.to route_command("assign US123 to joe.simmons@example.com").to(:assign_item) }
    it { is_expected.to route_command("assign US123 to Joe Simmons").to(:assign_item) }
    it { is_expected.to route_command("assign US123 to me").to(:assign_item) }

    it { is_expected.to_not route_command("US123 not a command").to(:item_summary) }

    it { is_expected.to route_command("projects").to(:list_projects) }
    it { is_expected.to route_command("today").to(:project_summary) }

    context "with configured custom defect/story pattern" do

      before(:each) do
        configure_patterns(:defect => /ALM\d+/, :story => /XYZ\d+/)
      end

      it { is_expected.to route("How far along is ALM123?").to(:item_summary)  }
      it { is_expected.to route("How far along is DE123?").to(:item_summary)  }
      it { is_expected.to route("How far along is XYZ123?").to(:item_summary)  }
      it { is_expected.to route("How far along is US123?").to(:item_summary)  }

    end

    context "with read_only option" do

      before(:each) do
        allow(subject.config).to receive(:read_only).and_return(true)
        described_class.routes.clear
        subject.define_routes
      end

      it { is_expected.to_not route_command("TA123 started").to(:update_item_state) }
      it { is_expected.to_not route_command("TA123 done").to(:update_item_state) }
      it { is_expected.to_not route_command("DE123 fixed").to(:update_item_state) }
      it { is_expected.to_not route_command("DE123 rejected").to(:update_item_state) }
      it { is_expected.to_not route_command("US123 accepted").to(:update_item_state) }
      it { is_expected.to_not route_command("TA123 blocked").to(:block_item) }
      it { is_expected.to_not route_command("TA123 unblocked").to(:unblock_item) }
      it { is_expected.to_not route_command("US123 ready").to(:mark_item_ready) }
      it { is_expected.to_not route_command("US123 not ready").to(:mark_item_not_ready) }
      it { is_expected.to_not route_command("delete TA123").to(:delete_task) }

    end

  end

  describe "finding stories", :focus => true do

    context "with no story pattern configured" do

      it "looks for story by ID only" do
        stub_find
        expect_any_instance_of(described_class).to     receive(:find_items_by_type_and_id).with(:hierarchical_requirement, 'US123').and_return([mock_story])
        expect_any_instance_of(described_class).to_not receive(:find_items_by_type_and_id_in_name)
        send_message("How far along is US123?")
      end

      it "does not fall back to looking for story by ID in name" do
        stub_find
        expect_any_instance_of(described_class).to     receive(:find_items_by_type_and_id).with(:hierarchical_requirement, 'US123').and_return([])
        expect_any_instance_of(described_class).to_not receive(:find_items_by_type_and_id_in_name)
        send_message("How far along is US123?")
      end

    end

    context "with Rally story pattern configured" do

      before(:each) do
        configure_patterns(:story => /US\d+/)
      end

      it "looks for story by ID in name first" do
        stub_find
        expect_any_instance_of(described_class).to     receive(:find_items_by_type_and_id_in_name).with(:hierarchical_requirement, 'US123').and_return([mock_story])
        expect_any_instance_of(described_class).to_not receive(:find_items_by_type_and_id)
        send_message("How far along is US123?")
      end

      it "falls back to looking for story by ID" do
        stub_find
        allow_any_instance_of(described_class).to  receive(:find_items_by_type_and_id_in_name).and_return([])
        expect_any_instance_of(described_class).to receive(:find_items_by_type_and_id).with(:hierarchical_requirement, 'US123').and_return([mock_story])
        send_message("How far along is US123?")
      end
    end

    context "with non-Rally story pattern configured" do

      before(:each) do
        configure_patterns(:story => /XYZ\d+/)
      end

      context "when looking by non-Rally ID" do
        it "looks for story by ID in name" do
          stub_find
          expect_any_instance_of(described_class).to receive(:find_items_by_type_and_id_in_name).with(:hierarchical_requirement, 'XYZ123').and_return([mock_story])
          send_message("How far along is XYZ123?")
        end

        it "does not fall back to looking for story by ID" do
          stub_find
          allow_any_instance_of(described_class).to      receive(:find_items_by_type_and_id_in_name).with(:hierarchical_requirement, 'XYZ123').and_return([])
          expect_any_instance_of(described_class).to_not receive(:find_items_by_type_and_id)
          send_message("How far along is XYZ123?")
        end
      end

      context "when looking by Rally ID" do

        it "looks for story by ID only" do
          stub_find
          expect_any_instance_of(described_class).to     receive(:find_items_by_type_and_id).with(:hierarchical_requirement, 'US123').and_return([mock_story])
          expect_any_instance_of(described_class).to_not receive(:find_items_by_type_and_id_in_name)
          send_message("How far along is US123?")
        end

        it "does not fall back to looking for story by ID in name" do
          stub_find
          expect_any_instance_of(described_class).to     receive(:find_items_by_type_and_id).with(:hierarchical_requirement, 'US123').and_return([])
          expect_any_instance_of(described_class).to_not receive(:find_items_by_type_and_id_in_name)
          send_message("How far along is US123?")
        end

      end

    end

    describe "finding defects", :focus => true do

      context "with no defect pattern configured" do

        it "looks for defect by ID only" do
          stub_find
          expect_any_instance_of(described_class).to     receive(:find_items_by_type_and_id).with(:defect, 'DE123').and_return([mock_defect])
          expect_any_instance_of(described_class).to_not receive(:find_items_by_type_and_id_in_name)
          send_message("How far along is DE123?")
        end

        it "does not fall back to looking for defect by ID in name" do
          stub_find
          expect_any_instance_of(described_class).to     receive(:find_items_by_type_and_id).with(:defect, 'DE123').and_return([])
          expect_any_instance_of(described_class).to_not receive(:find_items_by_type_and_id_in_name)
          send_message("How far along is DE123?")
        end

      end

      context "with Rally defect pattern configured" do

        before(:each) do
          configure_patterns(:defect => /DE\d+/)
        end

        it "looks for defect by ID in name first" do
          stub_find
          expect_any_instance_of(described_class).to     receive(:find_items_by_type_and_id_in_name).with(:defect, 'DE123').and_return([mock_defect])
          expect_any_instance_of(described_class).to_not receive(:find_items_by_type_and_id)
          send_message("How far along is DE123?")
        end

        it "falls back to looking for defect by ID" do
          stub_find
          allow_any_instance_of(described_class).to  receive(:find_items_by_type_and_id_in_name).and_return([])
          expect_any_instance_of(described_class).to receive(:find_items_by_type_and_id).with(:defect, 'DE123').and_return([mock_defect])
          send_message("How far along is DE123?")
        end

      end

      context "with non-Rally defect pattern configured" do

        before(:each) do
          configure_patterns(:defect => /ALM\d+/)
        end

        context "when looking by non-Rally ID" do

          it "looks for defect by ID in name" do
            stub_find
            expect_any_instance_of(described_class).to receive(:find_items_by_type_and_id_in_name).with(:defect, 'ALM123').and_return([mock_defect])
            send_message("How far along is ALM123?")
          end

          it "does not fall back to looking for defect by ID" do
            stub_find
            allow_any_instance_of(described_class).to      receive(:find_items_by_type_and_id_in_name).with(:defect, 'ALM123').and_return([])
            expect_any_instance_of(described_class).to_not receive(:find_items_by_type_and_id)
            send_message("How far along is ALM123?")
          end

        end

        context "when looking by Rally ID" do

          it "looks for defect by ID only" do
            stub_find
            expect_any_instance_of(described_class).to     receive(:find_items_by_type_and_id).with(:defect, 'DE123').and_return([mock_story])
            expect_any_instance_of(described_class).to_not receive(:find_items_by_type_and_id_in_name)
            send_message("How far along is DE123?")
          end

          it "does not fall back to looking for story by ID in name" do
            stub_find
            expect_any_instance_of(described_class).to     receive(:find_items_by_type_and_id).with(:defect, 'DE123').and_return([])
            expect_any_instance_of(described_class).to_not receive(:find_items_by_type_and_id_in_name)
            send_message("How far along is DE123?")
          end

        end

      end

    end

    describe "finding tasks", :focus => true do

      it "looks for task by ID only" do
        stub_find
        expect_any_instance_of(described_class).to     receive(:find_items_by_type_and_id).with(:task, 'TA123').and_return([mock_task])
        expect_any_instance_of(described_class).to_not receive(:find_items_by_type_and_id_in_name)
        send_message("How far along is TA123?")
      end

      it "does not fall back to looking for taks by ID in name" do
        stub_find
        expect_any_instance_of(described_class).to     receive(:find_items_by_type_and_id).with(:task, 'TA123').and_return([])
        expect_any_instance_of(described_class).to_not receive(:find_items_by_type_and_id_in_name)
        send_message("How far along is TA123?")
      end

    end

  end

  describe 'defect summary' do

    it "displays the defect's parent's ID" do
      stub_find([mock_defect(:requirement => mock_story(:formatted_i_d => 'US345'))])
      send_message("DE123")
      expect(replies.first).to eq('[US345] → [DE123] Error when placing order (@joe, open)')
    end

    it "displays the defect's parent's ID in name if available" do
      configure_patterns(:story => /XYZ\d+/)
      stub_find([mock_defect(:requirement => mock_story(:name => '[XYZ123] Search'))])
      send_message("DE123")
      expect(replies.first).to eq('[XYZ123] → [DE123] Error when placing order (@joe, open)')
    end

    it "displays the defect's name, not prefixed with Rally ID, if defect contains the configured defect ID pattern" do
      configure_patterns(:defect => /ALM\d+/)
      stub_find([mock_defect(:name => 'ALM123 Submitted order displayed with incorrect state')])
      send_message("Who can look at ALM123?")
      expect(replies.last).to eq('ALM123 Submitted order displayed with incorrect state (@joe, open)')
    end

    it "displays the defect's name, prefixed with Rally ID, if defect name does not contain the configured defect ID pattern" do
      configure_patterns(:defect => /ALM\d+/)
      stub_find([mock_defect(:formatted_i_d => 'DE456', :name => 'Submitted order displayed with incorrect state')])
      send_message("Who can look at DE123?")
      expect(replies.last).to eq('[DE456] Submitted order displayed with incorrect state (@joe, open)')
    end

    it "displays the defect's name, prefixed with Rally ID, if no defect ID pattern is configured" do
      configure_patterns(:defect => nil)
      stub_find([mock_defect(:formatted_i_d => 'DE456', :name => 'Submitted order displayed with incorrect state')])
      send_message("Who can look at DE123?")
      expect(replies.last).to eq('[DE456] Submitted order displayed with incorrect state (@joe, open)')
    end

    it "displays the defect's name, prefixed with Rally ID, if defect contains configured defect ID pattern but defect is referred to by Rally ID instead" do
      configure_patterns(:defect => /ALM\d+/)
      stub_find([mock_defect(:formatted_i_d => 'DE456', :name => 'ALM123 Submitted order displayed with incorrect state')])
      send_message("Who can look at DE456?")
      expect(replies.last).to eq('[DE456] ALM123 Submitted order displayed with incorrect state (@joe, open)')
    end

    it "displays the defect's state" do
      stub_find([mock_defect(:state => 'Fixed')])
      send_message("Who can look at DE123?")
      expect(replies.last).to eq('[DE123] Error when placing order (@joe, fixed)')
    end

    it "displays the release the defect was fixed in, for fixed defects" do
      stub_find([mock_defect(:state => 'Fixed', :release => '4.0.0-RC2')])
      send_message("Who can look at DE123?")
      expect(replies.last).to eq('[DE123] Error when placing order (@joe, fixed in 4.0.0-RC2)')
    end

    it "displays the release the defect was fixed in, for closed defects" do
      stub_find([mock_defect(:state => 'Closed', :release => '4.0.0-RC2')])
      send_message("Who can look at DE123?")
      expect(replies.last).to eq('[DE123] Error when placing order (@joe, closed, fixed in 4.0.0-RC2)')
    end

    it "displays the defect's owner by hipchat name if display_name is configured as :hipchat_name (default)" do
      roster = mock_roster([mock_roster_item('email' => 'janet.simmons@email.com', 'mention_name' => 'janet')])
      allow_any_instance_of(described_class).to receive(:roster).and_return(roster)
      stub_find([mock_defect(:owner => double(:email_address => 'janet.simmons@email.com'))])
      send_message("Who can look at DE123?")
      expect(replies.last).to eq('[DE123] Error when placing order (@janet, open)')
    end

    it "displays the defect's owner by full name if display_name is configured as :hipchat_name (default) but user is not found in roster" do
      empty_roster = mock_roster([])
      allow_any_instance_of(described_class).to receive(:roster).and_return(empty_roster)
      stub_find([mock_defect(:owner => double(:email_address => 'janet.simmons@email.com', :first_name => 'Janet', :last_name => 'Simmons'))])
      send_message("Who can look at DE123?")
      expect(replies.last).to eq('[DE123] Error when placing order (Janet Simmons, open)')
    end

    it "displays the defect's owner by first name if display_name is configured as :first_name" do
      allow(subject.config).to receive(:display_name).and_return(:first_name)
      stub_find([mock_defect(:owner => double(:first_name => 'Janet'))])
      send_message("Who can look at DE123?")
      expect(replies.last).to eq('[DE123] Error when placing order (Janet, open)')
    end

    it "displays the defect's owner by first name if display_name is configured as :full_name" do
      allow(subject.config).to receive(:display_name).and_return(:full_name)
      stub_find([mock_defect(:owner => double(:first_name => 'Janet', :last_name => 'Simmons'))])
      send_message("Who can look at DE123?")
      expect(replies.last).to eq('[DE123] Error when placing order (Janet Simmons, open)')
    end

    it "does not display the defect's owner if not available" do
      stub_find([mock_defect(:owner => nil)])
      send_message("Who can look at DE123?")
      expect(replies.last).to eq('[DE123] Error when placing order (open)')
    end

  end

  describe 'story summary' do

    before do
      Timecop.freeze(DateTime.parse("'2014-09-04'T04:00:00.000Z"))
    end

    after do
      Timecop.return
    end

    it "displays the story's name, prefixed with Rally ID, if story name does not contain the configured story ID pattern" do
      configure_patterns(:story => /US\d+/)
      stub_find([mock_story(:formatted_i_d => 'US789', :name => 'Refactor User class')])
      send_message("Where are we with US123?")
      expect(replies.last).to eq('[US789] Refactor User class (5 points, @joe, accepted, was scheduled to drop Sep 1)')
    end

    it "displays the story's name, prefixed with Rally ID, if no story ID pattern is configured" do
      configure_patterns(:story => nil)
      stub_find([mock_story(:formatted_i_d => 'US789', :name => 'Refactor User class')])
      send_message("Where are we with US123?")
      expect(replies.last).to eq('[US789] Refactor User class (5 points, @joe, accepted, was scheduled to drop Sep 1)')
    end

    it "displays the story's name, not prefixed with Rally ID, if story contains the configured story ID pattern" do
      configure_patterns(:story => /US\d+/)
      stub_find([mock_story(:name => '[US465] User sorts orders')])
      send_message("Where are we with US465?")
      expect(replies.last).to eq('[US465] User sorts orders (5 points, @joe, accepted, was scheduled to drop Sep 1)')
    end

    it "displays the story's name, prefixed with Rally ID, if story contains configured story ID pattern but story is referred to by Rally ID instead" do
      configure_patterns(:story => /US\d+/)
      stub_find([mock_story(:formatted_i_d => 'US123', :name => '[US465] User sorts orders')])
      send_message("Where are we with US123?")
      expect(replies.last).to eq('[US123] [US465] User sorts orders (5 points, @joe, accepted, was scheduled to drop Sep 1)')
    end

    it "displays the story's state" do
      stub_find([mock_story(:schedule_state => 'In-Progress')])
      send_message("Where are we with US123?")
      expect(replies.last).to eq('[US123] User places an order (5 points, @joe, in-progress, was scheduled to drop Sep 1)')
    end

    it "displays the story's custom state if a custom state field is configured" do
      allow(subject.config).to receive(:state_field).and_return(double(:story => :custom_kanban_state))
      stub_find([mock_story(:elements => {:custom_kanban_state => 'Code Review'})])
      send_message("Where are we with US123?")
      expect(replies.last).to eq('[US123] User places an order (5 points, @joe, code review, was scheduled to drop Sep 1)')
    end

    it "displays whether the story is ready" do
      stub_find([mock_story(:schedule_state => 'Completed', :ready => 'true')])
      send_message("Where are we with US123?")
      expect(replies.last).to eq('[US123] User places an order (5 points, @joe, completed and ready, was scheduled to drop Sep 1)')
    end

    it "displays the story's target date (in the past)" do
      stub_find([mock_story(:target_date => '2014-09-02')])
      send_message("Where are we with US123?")
      expect(replies.last).to eq('[US123] User places an order (5 points, @joe, accepted, was scheduled to drop Sep 2)')
    end

    it "displays the story's target date (yesterday)" do
      stub_find([mock_story(:target_date => '2014-09-03')])
      send_message("Where are we with US123?")
      expect(replies.last).to eq('[US123] User places an order (5 points, @joe, accepted, was scheduled to drop yesterday)')
    end

    it "displays the story's target date (today)" do
      stub_find([mock_story(:target_date => '2014-09-04')])
      send_message("Where are we with US123?")
      expect(replies.last).to eq('[US123] User places an order (5 points, @joe, accepted, dropping today)')
    end

    it "displays the story's target date (tomorrow)" do
      stub_find([mock_story(:target_date => '2014-09-05')])
      send_message("Where are we with US123?")
      expect(replies.last).to eq('[US123] User places an order (5 points, @joe, accepted, dropping tomorrow)')
    end

    it "displays the story's target date (in the future)" do
      stub_find([mock_story(:target_date => '2014-09-06')])
      send_message("Where are we with US123?")
      expect(replies.last).to eq('[US123] User places an order (5 points, @joe, accepted, dropping Sep 6)')
    end

    it "doesn't choke when target date is not set" do
      stub_find([mock_story(:target_date => nil)])
      send_message("Where are we with US123?")
      expect(replies.last).to eq('[US123] User places an order (5 points, @joe, accepted)')
    end

    it "displays the story's release if available" do
      stub_find([mock_story(:release => double(:name => '4.0-RC11'))])
      send_message("Where are we with US123?")
      expect(replies.last).to eq('[US123] User places an order (5 points, @joe, accepted, dropping/dropped with release 4.0-RC11)')
    end

    it "displays the story's release if available (for client accepted stories)" do
      stub_find([mock_story(:schedule_state => 'Client Accepted', :release => double(:name => '4.0-RC11'))])
      send_message("Where are we with US123?")
      expect(replies.last).to eq('[US123] User places an order (5 points, @joe, client accepted, dropped with release 4.0-RC11)')
    end

    it "displays when the story is blocked with no reason provided" do
      stub_find([mock_story(:blocked => 'true', :blocked_reason => nil)])
      send_message("Where are we with US123?")
      expect(replies.last).to eq('[US123] User places an order (5 points, @joe, accepted, blocked, was scheduled to drop Sep 1)')
    end

    it "displays when the story is blocked with reason provided" do
      stub_find([mock_story(:blocked => 'true', :blocked_reason => "Missing code review")])
      send_message("Where are we with US123?")
      expect(replies.last).to eq('[US123] User places an order (5 points, @joe, accepted, blocked by "Missing code review", was scheduled to drop Sep 1)')
    end

    it "displays the story's owner" do
      roster = mock_roster([mock_roster_item('email' => 'janet.simmons@email.com', 'mention_name' => 'janet')])
      allow_any_instance_of(described_class).to receive(:roster).and_return(roster)
      stub_find([mock_story(:owner => double(:email_address => 'janet.simmons@email.com'))])
      send_message("Where are we with US123?")
      expect(replies.last).to eq('[US123] User places an order (5 points, @janet, accepted, was scheduled to drop Sep 1)')
    end

    it "does not display the story's owner if it's not available" do
      stub_find([mock_story(:owner => nil)])
      send_message("Where are we with US123?")
      expect(replies.last).to eq('[US123] User places an order (5 points, accepted, was scheduled to drop Sep 1)')
    end

    it "displays the story's size" do
      stub_find([mock_story(:plan_estimate => '8.0')])
      send_message("Where are we with US123?")
      expect(replies.last).to eq('[US123] User places an order (8 points, @joe, accepted, was scheduled to drop Sep 1)')
    end

    it "displays the size of 1 point stories correctly" do
      stub_find([mock_story(:plan_estimate => '1.0')])
      send_message("Where are we with US123?")
      expect(replies.last).to eq('[US123] User places an order (1 point, @joe, accepted, was scheduled to drop Sep 1)')
    end

    it "displays the size of 0 point stories correctly" do
      stub_find([mock_story(:plan_estimate => '0.0')])
      send_message("Where are we with US123?")
      expect(replies.last).to eq('[US123] User places an order (0 points, @joe, accepted, was scheduled to drop Sep 1)')
    end

    it "does not display the story's size if it is not set" do
      stub_find([mock_story(:plan_estimate => nil)])
      send_message("Where are we with US123?")
      expect(replies.last).to eq('[US123] User places an order (@joe, accepted, was scheduled to drop Sep 1)')
    end

    it "displays the story's tags" do
      stub_find([mock_story(:tags => [double(:name => 'green'), double(:name => 'blue')])])
      send_message("Where are we with US123?")
      expect(replies.last).to eq('[US123] User places an order (5 points, @joe, accepted, was scheduled to drop Sep 1, green, blue)')
    end

    it "displays the story's uppercase tags in lowercase" do
      stub_find([mock_story(:tags => [double(:name => 'Green'), double(:name => 'Blue')])])
      send_message("Where are we with US123?")
      expect(replies.last).to eq('[US123] User places an order (5 points, @joe, accepted, was scheduled to drop Sep 1, green, blue)')
    end

  end

  describe 'task summary' do

    it "displays the task's parent's ID" do
      stub_find([mock_task(:work_product => mock_story(:formatted_i_d => 'US345'))])
      send_message("TA123")
      expect(replies.first).to eq('[US345] → [TA123] Code review (@joe, defined)')
    end

    it "displays the task's parent's ID in name if available" do
      configure_patterns(:story => /XYZ\d+/)
      stub_find([mock_task(:work_product => mock_story(:name => '[XYZ123] Search'))])
      send_message("TA123")
      expect(replies.first).to eq('[XYZ123] → [TA123] Code review (@joe, defined)')
    end

    it "displays the task's ID" do
      stub_find([mock_task(:formatted_i_d => 'TA567')])
      send_message("TA123")
      expect(replies.first).to eq('[US123] → [TA567] Code review (@joe, defined)')
    end

    it "displays the task's name" do
      stub_find([mock_task(:name => 'Architecture review')])
      send_message("TA123")
      expect(replies.first).to eq('[US123] → [TA123] Architecture review (@joe, defined)')
    end

    it "displays the task's state" do
      stub_find([mock_task(:state => 'In-Progress')])
      send_message("TA123")
      expect(replies.first).to eq('[US123] → [TA123] Code review (@joe, in-progress)')
    end

    it "displays the task's owner" do
      roster = mock_roster([mock_roster_item('email' => 'janet.simmons@email.com', 'mention_name' => 'janet')])
      allow_any_instance_of(described_class).to receive(:roster).and_return(roster)
      stub_find([mock_task(:owner => double(:email_address => 'janet.simmons@email.com'))])
      send_message("TA123")
      expect(replies.first).to eq('[US123] → [TA123] Code review (@janet, defined)')
    end

    it "displays when the task is blocked with no reason provided" do
      stub_find([mock_task(:blocked => 'true', :blocked_reason => nil)])
      send_message("TA123")
      expect(replies.first).to eq('[US123] → [TA123] Code review (@joe, defined, blocked)')
    end

    it "displays when the task is blocked with a reason provided" do
      stub_find([mock_task(:blocked => 'true', :blocked_reason => "Crucible down")])
      send_message("TA123")
      expect(replies.first).to eq('[US123] → [TA123] Code review (@joe, defined, blocked by "Crucible down")')
    end

  end

  describe 'story details' do

    it "finds the story" do
      stub_find
      expect_any_instance_of(described_class).to receive(:find_items_by_type_and_id).with(:hierarchical_requirement, 'US123').and_return([mock_story])
      send_command('US123')
    end

    it "displays 'not found' message if it can't find the story" do
      stub_find([])
      send_command('US123')
      expect(replies.last).to eq("Could not find US123")
    end

    it "displays the story's summary, prefixed by Rally ID if no story pattern is configured" do
      stub_find([mock_story(:name => 'User sorts orders')])
      send_command("US123")
      expect(lines(replies.first).first).to eq('[US123] User sorts orders (5 points, @joe, accepted, was scheduled to drop Sep 1)')
    end

    it "displays the story's summary, not prefixed by Rally ID if story pattern is configured and story is reffered to by ID in name" do
      configure_patterns(:story => /US\d+/)
      stub_find([mock_story(:name => '[US345] User sorts orders')])
      send_command("US345")
      expect(lines(replies.first).first).to eq('[US345] User sorts orders (5 points, @joe, accepted, was scheduled to drop Sep 1)')
    end

    it "displays the story's tasks" do
      stub_find([mock_story(:tasks => [mock_task(:name => 'Code review')])])
      send_command("US123")
      expect(lines(replies.first).last).to eq('↳ [TA123] Code review (@joe, defined)')
    end

    it "displays the story's tasks's IDs" do
      stub_find([mock_story(:name => '[US465] User sorts orders', :tasks => [mock_task(:formatted_i_d => 'TA345')])])
      send_command("US123")
      expect(lines(replies.first).last).to eq('↳ [TA345] Code review (@joe, defined)')
    end

    it "displays the story's tasks's states" do
      stub_find([mock_story(:name => '[US465] User sorts orders', :tasks => [mock_task(:state => 'Completed')])])
      send_command("US123")
      expect(lines(replies.first).last).to eq('↳ [TA123] Code review (@joe, completed)')
    end

    it "displays the story's tasks's owners" do
      joe_roster_item = mock_roster_item('email' => 'joe.simmons@email.com', 'mention_name' => 'joe')
      janet_roster_item = mock_roster_item('email' => 'janet.simmons@email.com', 'mention_name' => 'janet')
      allow_any_instance_of(described_class).to receive(:roster).and_return(mock_roster([joe_roster_item, janet_roster_item]))
      stub_find([mock_story(:name => '[US465] User sorts orders', :tasks => [mock_task(:owner => double(:email_address => 'janet.simmons@email.com'))])])
      send_command("US123")
      expect(lines(replies.first).last).to eq('↳ [TA123] Code review (@janet, defined)')
    end

    it "displays 'No tasks' if the story has no tasks" do
      stub_find([mock_story(:name => '[US465] User sorts orders', :tasks => nil)])
      send_command("US123")
      expect(lines(replies.first).last).to eq('No tasks')
    end

  end

  describe 'defect details' do

    it "finds the defect" do
      stub_find
      expect_any_instance_of(described_class).to receive(:find_item).with('DE123').and_return(mock_defect)
      send_command('DE123')
    end

    it "displays 'not found' message if it can't find the defect" do
      stub_find([])
      send_command('DE123')
      expect(replies.last).to eq("Could not find DE123")
    end

    it "displays the defect's summary" do
      stub_find([mock_defect(:name => 'Error when placing order', :requirement => nil)])
      send_command("DE465")
      expect(lines(replies.first).last).to eq('[DE123] Error when placing order (@joe, open)')
    end

    it "displays the story the defect is raised against" do
      stub_find([mock_defect(:name => 'Error when placing order', :requirement => mock_story(:name => "User places order"))])
      send_command("DE465")
      lines = lines(replies.first)
      expect(lines.size).to eql(2)
      expect(lines.first).to eq('[US123] User places order (5 points, @joe, accepted, was scheduled to drop Sep 1)')
      expect(lines.last).to  eq('↳ [DE123] Error when placing order (@joe, open)')
    end

    it "does not display the story the defect is raised against if it isn't available" do
      stub_find([mock_defect(:name => 'Error when placing order', :requirement => nil)])
      send_command("DE465")
      lines = lines(replies.first)
      expect(lines.size).to eql(1)
      expect(lines.first).to eq('[DE123] Error when placing order (@joe, open)')
    end

  end

  describe "task details" do

    it "finds the task" do
      stub_find
      expect_any_instance_of(described_class).to receive(:find_item).with('TA123').and_return(mock_task)
      send_command('TA123')
    end

    it "displays 'not found' message if it can't find the task" do
      stub_find([])
      send_command('TA123')
      expect(replies.last).to eq("Could not find TA123")
    end

    it "displays the task's summary" do
      stub_find([mock_task(:name => 'Coding')])
      send_command("TA465")
      expect(lines(replies.first).last).to eq('↳ [TA123] Coding (@joe, defined)')
    end

    it "displays the tasks's story" do
      stub_find([mock_task(:name => 'Coding', :work_product => mock_story(:name => 'User sorts orders'))])
      send_command("TA465")
      lines = lines(replies.first)
      expect(lines.first).to eq('[US123] User sorts orders (5 points, @joe, accepted, was scheduled to drop Sep 1)')
      expect(lines.last).to eq('↳ [TA123] Coding (@joe, defined)')
    end

  end

  describe "item history" do

    it "finds the item" do
      expect_any_instance_of(described_class).to receive(:find_item).with('US123')
      send_command("US123 history")
    end

    it "displays 'not found' message if it can't find the item" do
      stub_find([])
      send_command("US123 history")
      expect(replies.last).to eq("Could not find US123")
    end

    it "lists an items's revision history" do
      revision_1 = double(:description => 'Original revision', :creation_date => '2014-11-13T17:54:26.305Z', :user => double(:first_name => 'Ingo'))
      revision_2 = double(:description => 'TARGET DATE added [2014-11-12]', :creation_date => '2014-11-14T08:31:26.305Z', :user => double(:first_name => 'Suzanne'))
      revision_history = double(:revisions => [revision_1, revision_2])
      stub_find([mock_story(:revision_history => revision_history)])
      send_command("US123 history")
      expect(lines(replies.last).first).to eq('[2014-11-13 05:54PM by Ingo] Original revision')
      expect(lines(replies.last).last).to eq('[2014-11-14 08:31AM by Suzanne] TARGET DATE added [2014-11-12]')
    end

  end

  describe "item comments" do

    it "finds the item" do
      expect_any_instance_of(described_class).to receive(:find_item).with('US123')
      send_command("US123 comments")
    end

    it "displays 'not found' message if it can't find the item" do
      stub_find([])
      send_command("US123 comments")
      expect(replies.last).to eq("Could not find US123")
    end

    it "lists an items's comments" do
      comment_1 = double(:text => 'The acceptance tests are useless', :creation_date => '2014-11-13T17:54:26.305Z', :user => double(:first_name => 'Rich'))
      comment_2 = double(:text => 'You are only saying that because they are not written in Scala', :creation_date => '2014-11-14T08:31:26.305Z', :user => double(:first_name => 'Ingo'))
      stub_find([mock_story(:discussion => [comment_1, comment_2])])
      send_command("US123 comments")
      expect(lines(replies.last).first).to eq('[2014-11-13 05:54PM by Rich] The acceptance tests are useless')
      expect(lines(replies.last).last).to eq('[2014-11-14 08:31AM by Ingo] You are only saying that because they are not written in Scala')
    end

    it "prints message if there are no comments" do
      stub_find([mock_story(:discussion => nil)])
      send_command("US123 comments")
      expect(replies.last).to eq('No comments')
    end

  end

  describe "item url" do

    it "finds the item" do
      expect_any_instance_of(described_class).to receive(:find_item).with('US123')
      send_command("US123 url")
    end

    it "displays 'not found' message if it can't find the item" do
      stub_find([])
      send_command("US123 url")
      expect(replies.last).to eq("Could not find US123")
    end

    it "responds with URL for story" do
      mock_api = double(:base_url => 'https://rally1.rallydev.com/slm')
      expect_any_instance_of(described_class).to receive(:rally_api).and_return(mock_api)
      expect_any_instance_of(described_class).to receive(:find_items).and_return([mock_story(:object_i_d => '0123456789')])
      send_command("US345 url")
      expect(replies.last).to eq('https://rally1.rallydev.com/#/detail/userstory/0123456789')
    end

    it "responds with URL for defect" do
      mock_api = double(:base_url => 'https://rally1.rallydev.com/slm')
      expect_any_instance_of(described_class).to receive(:rally_api).and_return(mock_api)
      expect_any_instance_of(described_class).to receive(:find_items).and_return([mock_defect(:object_i_d => '0123456789')])
      send_command("DE345 url")
      expect(replies.last).to eq('https://rally1.rallydev.com/#/detail/defect/0123456789')
    end

    it "responds with URL for task" do
      mock_api = double(:base_url => 'https://rally1.rallydev.com/slm')
      expect_any_instance_of(described_class).to receive(:rally_api).and_return(mock_api)
      expect_any_instance_of(described_class).to receive(:find_items).and_return([mock_task(:object_i_d => '0123456789')])
      send_command("TA345 url")
      expect(replies.last).to eq('https://rally1.rallydev.com/#/detail/task/0123456789')
    end

  end

  describe "update item state" do

    it "finds task" do
      api = double(:find => [])
      expect(api).to receive(:find).with(:task)
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command("TA123 started")
    end

    it "finds defect" do
      api = double(:find => [])
      expect(api).to receive(:find).with(:defect)
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command("DE123 started")
    end

    it "finds story" do
      api = double(:find => [])
      expect(api).to receive(:find).with(:hierarchical_requirement)
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command("US123 accepted")
    end

    it "responds with 'not found' message if item is not found" do
      stub_find([])
      send_command("TA123 started")
      expect(replies.last).to eq("Could not find TA123")
    end

    it "starts task" do
      task = mock_task
      expect(task).to receive(:update).with(:state => 'In-Progress')
      api = double(:find => [task], :user => 'Joe', :create => true)
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command("TA123 started")
    end

    it "completes task" do
      task = mock_task
      expect(task).to receive(:update).with(:state => 'Completed')
      api = double(:find => [task], :user => 'Joe', :create => true)
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command("TA123 done")
    end

    it "starts defect" do
      defect = mock_defect
      expect(defect).to receive(:update).with(:state => 'Open')
      api = double(:find => [defect], :user => 'Joe', :create => true)
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command("DE123 started")
    end

    it "fixes defect" do
      defect = mock_defect
      expect(defect).to receive(:update).with(:state => 'Fixed')
      api = double(:find => [defect], :user => 'Joe', :create => true)
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command("DE123 fixed")
    end

    it "rejects defect" do
      defect = mock_defect
      expect(defect).to receive(:update).with(:state => 'Rejected')
      api = double(:find => [defect], :user => 'Joe', :create => true)
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command("DE123 rejected")
    end

    it "accepts story" do
      story = mock_story
      expect(story).to receive(:update).with(:schedule_state => 'Accepted')
      api = double(:find => [story], :user => 'Joe', :create => true)
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command("US123 accepted")
    end

    it "creates a comment documenting the update" do
      allow(user).to receive(:name).and_return('Jane')
      task = mock_task(:update => true)
      api = double(:find => [task], :user => 'Joe')
      expect(api).to receive(:create).with(:conversation_post, {
        :artifact => task,
        :text     => "'State' updated to 'In-Progress' by Jane via Lita",
        :user     => "Joe"
      })
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command("TA123 started")
    end

    it "displays message if the update fails" do
      task = mock_task(:formatted_i_d => 'TA567')
      allow(task).to receive(:update) do
        raise
      end
      api = double(:find => [task])
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command("TA567 started")
      expect(replies.last).to eq('Could not update TA567')
    end

    it "does not allow fixing a task (only valid for defects)" do
      task = mock_task(:update => true)
      api = double(:find => [task], :user => 'Joe', :create => true)
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command("TA123 fixed")
      expect(replies.last).to eq("TA123 (task) can be started or done, but not fixed")
    end

    it "does not allow rejecting a task (only valid for defects)" do
      task = mock_task(:update => true)
      api = double(:find => [task], :user => 'Joe', :create => true)
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command("TA123 rejected")
      expect(replies.last).to eq("TA123 (task) can be started or done, but not rejected")
    end

    it "does not allow completing a defect (only valid for tasks)" do
      task = mock_task(:update => true)
      api = double(:find => [task], :user => 'Joe', :create => true)
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command("DE123 done")
      expect(replies.last).to eq("DE123 (defect) can be started, fixed or rejected, but not done")
    end

    it "does not allow fixing a story (only valid for defects)" do
      story = mock_story(:update => true)
      api = double(:find => [story], :user => 'Joe', :create => true)
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command("US123 fixed")
      expect(replies.last).to eq("US123 (story) can be accepted, but not fixed")
    end

    context "multiple items" do

      it "updates all items" do
        task_one = mock_task
        expect(task_one).to receive(:update).with(:state => 'In-Progress')
        task_two = mock_task
        expect(task_two).to receive(:update).with(:state => 'In-Progress')
        expect_any_instance_of(described_class).to receive(:find_item).with('TA123').and_return(task_one)
        expect_any_instance_of(described_class).to receive(:find_item).with('TA234').and_return(task_two)
        send_command("TA123 TA234 started")
      end

      it "does not update the same item multiple times" do
        task = mock_task
        expect(task).to receive(:update).with(:state => 'In-Progress').exactly(:once)
        expect_any_instance_of(described_class).to receive(:find_item).with('TA123').and_return(task)
        send_command("TA123 ta123 started")
      end

      it "responds with error message if number of items exceeds the configured limit" do
        allow(subject.config).to receive(:multiple_items_limit).and_return(5)
        send_command("TA1 TA2 TA3 TA4 TA5 TA6 started")
        expect(replies.last).to eq("Sorry, you configured me to only handle 5 items at a time")
      end

    end

  end

  describe "block story without reason" do

    it "finds story" do
      api = double(:find => [])
      expect(api).to receive(:find).with(:hierarchical_requirement)
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command("US123 blocked")
    end

    it "responds with 'not found' message if story is not found" do
      stub_find([])
      send_command("US123 blocked")
      expect(replies.last).to eq("Could not find US123")
    end

    it "blocks the story" do
      story = mock_defect
      expect(story).to receive(:update).with(:blocked => true, :blocked_reason => nil)
      api = double(:find => [story], :user => 'Joe', :create => true)
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command("US123 blocked")
    end

    it "creates a comment recording who blocked the story" do
      allow(user).to receive(:name).and_return('Jane')
      story = mock_story(:update => true)
      api = double(:find => [story], :user => 'Joe')
      expect(api).to receive(:create).with(:conversation_post, {
        :artifact => story,
        :text     => "Blocked by Jane via Lita",
        :user     => "Joe"
      })
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command("US123 blocked")
    end

  end

  describe "block story with reason" do

    it "finds story" do
      api = double(:find => [])
      expect(api).to receive(:find).with(:hierarchical_requirement)
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command('US123 blocked by "Coffee machine broken"')
    end

    it "responds with 'not found' message if story is not found" do
      stub_find([])
      send_command('US123 blocked by "Coffee machine broken"')
      expect(replies.last).to eq("Could not find US123")
    end

    it "blocks the story and updates the blocked reason" do
      story = mock_defect
      expect(story).to receive(:update).with(:blocked => true, :blocked_reason => 'Coffee machine broken')
      api = double(:find => [story], :user => 'Joe', :create => true)
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command('US123 blocked by "Coffee machine broken"')
    end

    it "creates a comment recording who blocked the story" do
      allow(user).to receive(:name).and_return('Jane')
      story = mock_story(:update => true)
      api = double(:find => [story], :user => 'Joe')
      expect(api).to receive(:create).with(:conversation_post, {
        :artifact => story,
        :text     => "Blocked by Jane via Lita",
        :user     => "Joe"
      })
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command('US123 blocked by "Coffee machine broken"')
    end

  end

  describe "unblock story" do

    it "finds story" do
      mock_api = double(:find => [])
      allow(RallyRestAPI).to receive(:new).and_return(mock_api)
      expect_any_instance_of(described_class).to receive(:find_items_by_type_and_id).with(:hierarchical_requirement, 'US123').and_return([])
      send_command('US123 unblocked')
    end

    it "responds with 'not found' message if story is not found" do
      stub_find([])
      send_command('US123 unblocked')
      expect(replies.last).to eq("Could not find US123")
    end

    it "unblocks the story" do
      story = mock_defect
      expect(story).to receive(:update).with(:blocked => false)
      api = double(:find => [story], :user => 'Joe', :create => true)
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command('US123 unblocked')
    end

    it "creates a comment recording who unblocked the story" do
      allow(user).to receive(:name).and_return('Jane')
      story = mock_story(:update => true)
      api = double(:find => [story], :user => 'Joe')
      expect(api).to receive(:create).with(:conversation_post, {
        :artifact => story,
        :text     => "Unblocked by Jane via Lita",
        :user     => "Joe"
      })
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command('US123 unblocked')
    end

  end

  describe "mark story ready" do

    it "finds story" do
      stub_find
      expect_any_instance_of(described_class).to receive(:find_item).with('US123')
      send_command('US123 ready')
    end

    it "responds with 'not found' message if story is not found" do
      stub_find
      allow_any_instance_of(described_class).to receive(:find_item).with('US123').and_return(nil)
      send_command('US123 ready')
      expect(replies.last).to eq("Could not find US123")
    end

    it "marks the story as ready" do
      story = mock_story
      expect(story).to receive(:update).with(:ready => true)
      api = double(:find => [story], :user => 'Joe', :create => true)
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command('US123 ready')
    end

    it "creates a comment recording who unblocked the story" do
      allow(user).to receive(:name).and_return('Jane')
      story = mock_story(:update => true)
      api = double(:find => [story], :user => 'Joe')
      expect(api).to receive(:create).with(:conversation_post, {
        :artifact => story,
        :text     => "Marked ready by Jane via Lita",
        :user     => "Joe"
      })
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command('US123 ready')
    end

    it "displayes the updated story's summary if update succeeds" do
      story = mock_story(:update => true)
      api = double(:find => [story], :user => 'Joe', :create => true)
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command('US123 ready')
      expect(replies.last).to eql("[US123] User places an order (5 points, @joe, accepted, was scheduled to drop Sep 1)")
    end

  end

  describe "mark story not ready" do

    it "finds story" do
      stub_find
      expect_any_instance_of(described_class).to receive(:find_item).with('US123').and_return(nil)
      send_command('US123 not ready')
    end

    it "responds with 'not found' message if story is not found" do
      stub_find
      send_command('US123 not ready')
      expect(replies.last).to eq("Could not find US123")
    end

    it "marks the story as ready" do
      story = mock_story
      expect(story).to receive(:update).with(:ready => false)
      api = double(:find => [story], :user => 'Joe', :create => true)
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command('US123 not ready')
    end

    it "creates a comment recording who unblocked the story" do
      allow(user).to receive(:name).and_return('Jane')
      story = mock_story(:update => true)
      api = double(:find => [story], :user => 'Joe')
      expect(api).to receive(:create).with(:conversation_post, {
        :artifact => story,
        :text     => "Marked not ready by Jane via Lita",
        :user     => "Joe"
      })
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command('US123 not ready')
    end

    it "displayes the updated story's summary if update succeeds" do
      story = mock_story(:update => true)
      api = double(:find => [story], :user => 'Joe', :create => true)
      allow(RallyRestAPI).to receive(:new).and_return(api)
      send_command('US123 not ready')
      expect(replies.last).to eql("[US123] User places an order (5 points, @joe, accepted, was scheduled to drop Sep 1)")
    end

  end

  describe "delete task" do

    it "finds task" do
      stub_find
      expect_any_instance_of(described_class).to receive(:find_items_by_type_and_id).with(:task, 'TA123').and_return([])
      send_command('delete TA123')
    end

    it "deletes task" do
      task = mock_task
      expect(task).to receive(:delete)
      expect_any_instance_of(described_class).to receive(:find_items_by_type_and_id).with(:task, 'TA123').and_return([task])
      send_command('delete TA123')
    end

    it "confirms deletion" do
      task = mock_task(:delete => true)
      expect_any_instance_of(described_class).to receive(:find_items_by_type_and_id).with(:task, 'TA123').and_return([task])
      send_command('delete TA123')
      expect(replies.last).to eql("TA123 deleted")
    end

    it "responds with 'not found' message if task is not found" do
      stub_find([])
      send_command('delete TA123')
      expect(replies.last).to eq("Could not find TA123")
    end

  end

  describe "assign item" do

    it "finds user by HipChat mention name" do
      stub_find([mock_story])
      expect_any_instance_of(described_class).to receive(:find_user_by_hipchat_mention_name).with('@joe').and_return(nil)
      send_command('assign US123 to @joe')
    end

    it "finds user by full name" do
      stub_find([mock_story])
      expect_any_instance_of(described_class).to receive(:find_user_by_full_name).with('Joe Simmons').and_return(nil)
      send_command('assign US123 to Joe Simmons')
    end

    it "finds user by sending user's full name if 'me' is used" do
      allow(user).to receive(:name).and_return('Joe Simmons')
      stub_find([mock_story])
      expect_any_instance_of(described_class).to receive(:find_user_by_full_name).with('Joe Simmons').and_return(nil)
      send_command('assign US123 to me')
    end

    it "finds user by email address" do
      stub_find([mock_story])
      expect_any_instance_of(described_class).to receive(:find_user_by_email_address).with('joe.simmons@example.com').and_return(nil)
      send_command('assign US123 to joe.simmons@example.com')
    end

    it "responds with 'not found' message if user is not found" do
      stub_find([mock_story])
      expect_any_instance_of(described_class).to receive(:find_user).with('@joe').and_return(nil)
      send_command('assign US123 to @joe')
      expect(replies.last).to eq("Could not find @joe")
    end

    it "finds item" do
      allow_any_instance_of(described_class).to receive(:find_user).and_return(mock_user)
      expect_any_instance_of(described_class).to receive(:find_items_by_type_and_id).with(:hierarchical_requirement, 'US123').and_return([])
      send_command('assign US123 to @joe')
    end

    it "responds with 'not found' message if story is not found" do
      allow_any_instance_of(described_class).to receive(:find_user).and_return(mock_user)
      expect_any_instance_of(described_class).to receive(:find_items_by_type_and_id).with(:hierarchical_requirement, 'US123').and_return([])
      send_command('assign US123 to @joe')
      expect(replies.last).to eq("Could not find US123")
    end

    it "assigns the story" do
      story = mock_story
      user = mock_user(:name => 'Joe Simmons')
      api = double(:find => [story], :user => 'Joe', :create => true)
      allow(RallyRestAPI).to receive(:new).and_return(api)
      allow_any_instance_of(described_class).to receive(:find_user_by_hipchat_mention_name).with('@joe').and_return(user)
      expect(story).to receive(:update).with(:owner => user)
      send_command('assign US123 to @joe')
    end

    it "creates a comment recording who re-assigned the story" do
      allow(user).to receive(:name).and_return('Jane')
      story = mock_story(:update => true)
      api = double(:find => [story], :user => 'Joe')
      expect(api).to receive(:create).with(:conversation_post, {
        :artifact => story,
        :text     => "Assigned to Joe Simmons by Jane via Lita",
        :user     => "Joe"
      })
      allow(RallyRestAPI).to receive(:new).and_return(api)
      allow_any_instance_of(described_class).to receive(:find_user_by_hipchat_mention_name).with('@joe').and_return(mock_user(:name => 'Joe Simmons'))
      send_command('assign US123 to @joe')
    end

  end

  describe "unhandled commands" do

    it "displays apologetic and helpful message for unhandled command" do
      send_command("save the world")
      expect(replies).to_not be_empty
      expect(replies.last).to eq(I18n.translate('lita.handlers.rally.unhandled_command_message'))
    end

    it "displays apologetic and helpful message for unhandled command containing an item ID" do
      send_command("implement US123")
      expect(replies).to_not be_empty
      expect(replies.last).to eq(I18n.translate('lita.handlers.rally.unhandled_command_message'))
    end

    it "displays apologetic and helpful message for unhandled question" do
      send_command("what is the meaning of life?")
      expect(replies).to_not be_empty
      expect(replies.last).to eq(I18n.translate('lita.handlers.rally.unhandled_question_message'))
    end

  end

  describe "list projects" do

    it  "lists projects" do
      expect_any_instance_of(described_class).to receive(:projects).and_return([
        double(:name => 'Project 1'),
        double(:name => 'Project 2')
      ])
      send_command('projects')
      expect(lines(replies.first)).to eq(['Project 1', 'Project 2'])
    end

  end

  describe "project summary" do

    before do
      Timecop.freeze(DateTime.parse("2014-10-12T04:00:00.000Z"))
    end

    after do
      Timecop.return
    end

    it "Displays a 'unsupported' message if multiple projects are configured" do
      mock_api = double(:find => [])
      allow(RallyRestAPI).to receive(:new).and_return(mock_api)
      allow(subject.config.scope).to receive(:projects).and_return(['Project 1', 'Project 2'])
      send_command("today")
      expect(replies.last).to eq("Sorry, this command does not yet support multiple projects")
    end

    it "displays open defects" do
      mock_api = double
      allow(mock_api).to receive(:find).with(:project).and_return([])
      allow(mock_api).to receive(:find).with(:hierarchical_requirement).and_return([])
      allow(mock_api).to receive(:find).with(:defect).and_return([
        mock_defect(),
      ])
      allow(RallyRestAPI).to receive(:new).and_return(mock_api)

      send_command("today")
      expect(lines(replies.last)).to eq([
        '---------------------------------------',
        'DEFECTS (1)',
        '---------------------------------------',
        '[DE123] Error when placing order (@joe, open)'
      ])
    end

    it "displays stories that are late, due today, due tomorrow or upcoming" do
      mock_api = double
      allow(mock_api).to receive(:find).with(:defect).and_return([])
      allow(mock_api).to receive(:find).with(:project).and_return([])
      allow(mock_api).to receive(:find).with(:hierarchical_requirement).and_return([
        mock_story(:name => "A", :target_date => "2014-10-11T04:00:00.000Z"),
        mock_story(:name => "B", :target_date => "2014-10-12T04:00:00.000Z"),
        mock_story(:name => "C", :target_date => "2014-10-13T04:00:00.000Z"),
        mock_story(:name => "D", :target_date => "2014-10-14T04:00:00.000Z"),
      ])
      allow(RallyRestAPI).to receive(:new).and_return(mock_api)

      send_command("today")
      expect(lines(replies.last)).to eq([
        '---------------------------------------',
        "LATE (1)",
        '---------------------------------------',
        "[US123] A (5 points, @joe, accepted, was scheduled to drop yesterday)",
        '---------------------------------------',
        "TODAY (1)",
        '---------------------------------------',
        "[US123] B (5 points, @joe, accepted, dropping today)",
        '---------------------------------------',
        "TOMORROW (1)",
        '---------------------------------------',
        "[US123] C (5 points, @joe, accepted, dropping tomorrow)",
        '---------------------------------------',
        "UPCOMING (1)",
        '---------------------------------------',
        "[US123] D (5 points, @joe, accepted, dropping Oct 14)"
      ])
    end

    it "limits the display of upcoming stories to 3" do
      mock_api = double
      allow(mock_api).to receive(:find).with(:defect).and_return([])
      allow(mock_api).to receive(:find).with(:project).and_return([])
      allow(mock_api).to receive(:find).with(:hierarchical_requirement).and_return([
        mock_story(:name => "A", :target_date => "2014-10-14T04:00:00.000Z"),
        mock_story(:name => "B", :target_date => "2014-10-15T04:00:00.000Z"),
        mock_story(:name => "C", :target_date => "2014-10-16T04:00:00.000Z"),
        mock_story(:name => "D", :target_date => "2014-10-17T04:00:00.000Z"),
      ])
      allow(RallyRestAPI).to receive(:new).and_return(mock_api)

      send_command("today")
      expect(lines(replies.last)).to eq([
        '---------------------------------------',
        "UPCOMING (4)",
        '---------------------------------------',
        "[US123] A (5 points, @joe, accepted, dropping Oct 14)",
        "[US123] B (5 points, @joe, accepted, dropping Oct 15)",
        "[US123] C (5 points, @joe, accepted, dropping Oct 16)"
      ])
    end

    it "displays more than 3 upcoming stories if there are more stories scheduled for the same day as the third story" do
      mock_api = double
      allow(mock_api).to receive(:find).with(:defect).and_return([])
      allow(mock_api).to receive(:find).with(:project).and_return([])
      allow(mock_api).to receive(:find).with(:hierarchical_requirement).and_return([
        mock_story(:name => "A", :target_date => "2014-10-14T04:00:00.000Z"),
        mock_story(:name => "B", :target_date => "2014-10-14T04:00:00.000Z"),
        mock_story(:name => "C", :target_date => "2014-10-15T04:00:00.000Z"),
        mock_story(:name => "D", :target_date => "2014-10-15T04:00:00.000Z")
      ])
      allow(RallyRestAPI).to receive(:new).and_return(mock_api)

      send_command("today")
      expect(lines(replies.last)).to eq([
        '---------------------------------------',
        "UPCOMING (4)",
        '---------------------------------------',
        "[US123] A (5 points, @joe, accepted, dropping Oct 14)",
        "[US123] B (5 points, @joe, accepted, dropping Oct 14)",
        "[US123] C (5 points, @joe, accepted, dropping Oct 15)",
        "[US123] D (5 points, @joe, accepted, dropping Oct 15)"
      ])
    end

  end

end
