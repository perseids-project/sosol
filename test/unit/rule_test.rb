require 'test_helper'

class RuleTest < ActiveSupport::TestCase
  [
    { :tally_method => Decree::TALLY_METHODS[:percent],
      :trigger => 50.0, 
      :rule_floor => 33.0},
    { :tally_method => Decree::TALLY_METHODS[:count],
      :trigger => 2,
      :rule_floor => 1 }
  ].each do |method|
    context "a #{method[:tally_method]} decree" do
      setup do
        @decree = FactoryGirl.create(:decree,
                          :action => "approve",
                          :trigger => method[:trigger],
                          :tally_method => method[:tally_method],
                          :choices => "yes")
        @rule = FactoryGirl.create(:rule, :floor => method[:rule_floor], :expire_days => 1)
        @decree.rules << @rule
        # add some users to this decree's board
        3.times do |i|
          @decree.board.users << FactoryGirl.create(:user)
        end
      end
    
      teardown do
        @rule.destroy
        @decree.board.users.each {|u| u.destroy}
        @decree.board.destroy
        @decree.destroy
      end
    
      context "with a rule" do
        setup do
          @publication = FactoryGirl.create(:publication, :owner => @decree.board, :creator => @decree.board.users.first)
          @publication.branch_from_master
          @ddb_identifier = DDBIdentifier.new_from_template(@publication)
        end

        teardown do
          @publication.destroy
        end

        should "apply rule and perform action when rule is met" do
          #vote only once
          # travel in time
          Timecop.travel(1.day.ago)
          1.times do |v|
            FactoryGirl.create(:vote,
                    :publication => @publication,
                    :identifier_id => @ddb_identifier.id,
                    :user => @decree.board.users[v],
                    :choice => "yes")
          end

          # normally we wouldn't perform the action          
          assert !@decree.perform_action?(@ddb_identifier.votes)

          # and right now the rule isn't met
          assert !@decree.rules[0].apply_rule?(@ddb_identifier.votes)

          Timecop.return
          assert @decree.rules[0].apply_rule?(@ddb_identifier.votes)
        end


      end
    end
  end
  [
    { :tally_method => Decree::TALLY_METHODS[:count],
      :trigger => 3,
      :rule_floor => 1 }
  ].each do |method|
    context "a #{method[:tally_method]} decree" do
      setup do
        @decree = FactoryGirl.create(:decree,
                          :action => "approve",
                          :trigger => method[:trigger],
                          :tally_method => method[:tally_method],
                          :choices => "yes")
        @rule = FactoryGirl.create(:rule, :floor => method[:rule_floor],  :expire_days => 1)
        @decree.rules << @rule
        # add some users to this decree's board
        3.times do |i|
          @decree.board.users << FactoryGirl.create(:user)
        end
      end
    
      teardown do
        @rule.destroy
        @decree.board.users.each {|u| u.destroy}
        @decree.board.destroy
        @decree.destroy
      end
      context "with a rule" do
        setup do
          @publication = FactoryGirl.create(:publication, :owner => @decree.board, :creator => @decree.board.users.first)
          @publication.branch_from_master
          @ddb_identifier = DDBIdentifier.new_from_template(@publication)
        end

        teardown do
          @publication.destroy
          Timecop.return
        end

        should "consider all votes for a rule" do
          #vote only once
          # travel in time
          realtime = Time.now
          future = 2.days.from_now

          Timecop.travel(1.day.ago)
          FactoryGirl.create(:vote,
                  :publication => @publication,
                  :identifier_id => @ddb_identifier.id,
                  :user => @decree.board.users[0],
                  :choice => "yes")

          # normally we wouldn't perform the action          
          assert !@decree.perform_action?(@ddb_identifier.votes)

          # and right now the rule isn't met
          assert !@decree.rules[0].apply_rule?(@ddb_identifier.votes)

          Timecop.return
          Timecop.travel(realtime)

          vote2 = FactoryGirl.create(:vote,
                :publication => @publication,
                :identifier_id => @ddb_identifier.id,
                :user => @decree.board.users[1],
                :choice => "yes")

          # we need to force this vote on for some reason, the factory isn't adding it
          @ddb_identifier.votes << vote2 

          assert_equal 2, @ddb_identifier.votes.size
 
          # normally we wouldn't perform the action          
          assert !@decree.perform_action?(@ddb_identifier.votes)

          # and the rule still isn't met because there is a newer vote from today
          assert !@decree.rules[0].apply_rule?(@ddb_identifier.votes)

          # but if we travel to the future we should be able to apply the rules
          Timecop.travel(future)
          assert @decree.rules[0].apply_rule?(@ddb_identifier.votes)
        end        
      end
    end
  end
  [
    { :tally_method => Decree::TALLY_METHODS[:percent],
      :trigger => 75.0,
      :rule_floor => 50.0 },
    { :tally_method => Decree::TALLY_METHODS[:count],
      :trigger => 3, 
      :rule_floor => 2 }
  ].each do |method|
    context "a #{method[:tally_method]} decree" do
      setup do
        @decree = FactoryGirl.create(:decree,
                          :action => "approve",
                          :trigger => method[:trigger],
                          :tally_method => method[:tally_method],
                          :choices => "yes")
        @rule = FactoryGirl.create(:rule, :floor => method[:rule_floor], :expire_days => 1)
        @decree.rules << @rule
        # add some users to this decree's board
        3.times do |i|
          @decree.board.users << FactoryGirl.create(:user)
        end
      end
    
      teardown do
        @rule.destroy
        @decree.board.users.each {|u| u.destroy}
        @decree.board.destroy
        @decree.destroy
      end
    
      context "with a rule with a larger floor" do
        setup do
          @publication = FactoryGirl.create(:publication, :owner => @decree.board, :creator => @decree.board.users.first)
          @publication.branch_from_master
          @ddb_identifier = DDBIdentifier.new_from_template(@publication)
        end

        teardown do
          @publication.destroy
          Timecop.return
        end
        should "obey the rule floor" do
          yesterday = 1.day.ago
          realtime = Time.now
          future = 2.days.from_now
          Timecop.travel(yesterday)
          FactoryGirl.create(:vote,
                  :publication => @publication,
                  :identifier_id => @ddb_identifier.id,
                  :user => @decree.board.users[0],
                  :choice => "yes")
          Timecop.travel(future)
          # expire_time is met but no the floor
          assert !@decree.rules[0].apply_rule?(@ddb_identifier.votes)
          # do another vote yesterday
          Timecop.travel(yesterday)
          vote2 = FactoryGirl.create(:vote,
                :publication => @publication,
                :identifier_id => @ddb_identifier.id,
                :user => @decree.board.users[1],
                :choice => "yes")

          # we need to force this vote on for some reason, the factory isn't adding it
          @ddb_identifier.votes << vote2 
          Timecop.travel(future)
          assert @decree.perform_action?(@ddb_identifier.votes,@decree.rules[0].floor)
          # floor is met now too
          assert @decree.rules[0].apply_rule?(@ddb_identifier.votes)
          
        end
      end
    end
  end
end
