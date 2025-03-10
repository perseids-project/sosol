require 'test_helper'
require 'ddiff'

#require File.dirname(__FILE__) + '/session_set_controller'

=begin
This file tests the Pass Through Community workflow.

The Pass Through Community workflow is similar to a Master Community workflow (or the default SoSOL 
workflow) except that the publication/identifiers are not committed to the canon on finalize. 
Instead the changes made by the finalizer are copied back to the submitters origin publication.
Once the publication has been vetted by all the community boards, the "committed" version 
is either (a) submitted to the next community or (b) sent to an external agent.

=end

class PassThroughCommunityWorkflowTest < ActionController::IntegrationTest
  def compare_publications(a,b)

    pubs_are_matched = true
    a.identifiers.each do |aid|
      id_has_match = false
      b.identifiers.each do |bid|
        if (aid.class.to_s == bid.class.to_s && aid.title == bid.title)
          if (aid.xml_content == bid.xml_content)
            id_has_match = true
            Rails.logger.debug "Identifier match found"
          else
            if aid.xml_content == nil
              Rails.logger.debug a.title + " has nill " + aid.class.to_s + " identifier"
            end
            if bid.xml_content == nil
              Rails.logger.debug b.title + " has nill " + bid.class.to_s + " identifier"
            end
            Rails.logger.debug "Identifier diffs for " + a.title + " " + b.title + " " + aid.class.to_s + " " +  aid.title
            log_diffs(aid.xml_content.to_s, bid.xml_content.to_s )
            #Rails.logger.debug "full xml a " + aid.xml_content
            #Rails.logger.debug "full xml b " + bid.xml_content
          end
        end
      end

      if !id_has_match
        pubs_are_matched = false
        Rails.logger.debug "--Mis matched publication. Id " + aid.title + " " + aid.class.to_s + " are different"
      end
    end

    if pubs_are_matched
      Rails.logger.debug "Publications are matched"
    end

  end

  def log_diffs(a, b)
    a_to_b_diff = a.diff(b)

    plus_str = ""
    minus_str = ""
    a_to_b_diff.diffs.each do |d|
      d.each do |mod|
        if mod[0] == "+"
          plus_str = plus_str + mod[2].chr
        else
          minus_str = minus_str + mod[2].chr
        end
      end
    end

    Rails.logger.debug "added " + plus_str
    Rails.logger.debug "removed " + minus_str

  end

  def output_publication_info(publication)
    Rails.logger.info "-----Publication Info-----"
    Rails.logger.info "--Owner: " + publication.owner.name
    Rails.logger.info "--Title: " + publication.title
    Rails.logger.info "--Status: " + publication.status
    Rails.logger.info "--content"

    publication.identifiers.each do |id|
      Rails.logger.info "---ID title: " + id.title
      Rails.logger.info "---ID class:" + id.class.to_s
      Rails.logger.info "---ID content:"
      if id.xml_content
        Rails.logger.info id.xml_content
      else
        Rails.logger.info "NO CONTENT!"
      end
      #Rails.logger.info "== end Owner: " + publication.owner.name
    end
    Rails.logger.info "==end Owner: " + publication.owner.name
    Rails.logger.info "=====End Publication Info====="
  end
end

class PassThroughCommunityWorkflowTest < ActionController::IntegrationTest
  context "for community" do
    context "community testing" do
      setup do
        #Rails.logger.level = :debug
        Rails.logger.debug "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx community testing setup xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

        #users to put on the boards
        @board_user = FactoryGirl.create(:user, :name => "board_man_freaky_bob")
        @board_user_2 = FactoryGirl.create(:user, :name => "board_man_freaky_alice")

        #a user to submit publications
        @creator_user = FactoryGirl.create(:user, :name => "creator_freaky_bob")

        #master board user 
        @master_user = FactoryGirl.create(:user, :name => "master_freaky_bob")

        #a general member in the community
        @community_user = FactoryGirl.create(:user, :name => "community_freaky_bob")

        #set up the master community
        @master_community = FactoryGirl.create(:master_community, :is_default => true, :allows_self_signup => true )
        @master_community.members << @master_user
        @master_board = FactoryGirl.create(:master_community_board, :title => "SoSOLMaster", :community_id => @master_community.id)
        @master_board.users << @master_user
        @master_decree = FactoryGirl.create(:count_decree,
                                          :board => @master_board,
                                          :trigger => 1.0,
                                          :action => "approve",
                                          :choices => "ok")
        @master_board.decrees << @master_decree

        #set up the passthrough communities
        @test_community = FactoryGirl.create(:pass_through_community,
                                             :name => "test_freaky_community",
                                             :friendly_name => "testy",
                                             :allows_self_signup => true,
                                             #:abbreviation => "tc",
                                             :description => "a comunity for testing",
                                             :pass_to => @master_community.name)
        @test_community.members << @community_user
        @test_community.save

        #set up the community boards
        @meta_board = FactoryGirl.create(:hgv_meta_board, :title => "meta", :community_id => @test_community.id)
        @meta_board.users << @board_user
        @meta_decree = FactoryGirl.create(:count_decree,
                                          :board => @meta_board,
                                          :trigger => 1.0,
                                          :action => "approve",
                                          :choices => "ok")
        @meta_board.decrees << @meta_decree
        @test_community.boards << @meta_board


        @text_board = FactoryGirl.create(:board, :title => "text", :community_id => @test_community.id)
        @text_board.users << @board_user
        @text_decree = FactoryGirl.create(:count_decree,
                                          :board => @text_board,
                                          :trigger => 1.0,
                                          :action => "approve",
                                          :choices => "ok")
        @text_board.decrees << @text_decree
        @test_community.boards << @text_board

        # translation board isn't used, just created as a control
        @translation_board = FactoryGirl.create(:hgv_trans_board, :title => "translation", :community_id => @test_community.id)
        @translation_board.users << @board_user
        @translation_decree = FactoryGirl.create(:count_decree,
                                                 :board => @translation_board,
                                                 :trigger => 1.0,
                                                 :action => "approve",
                                                 :choices => "ok")
        @translation_board.decrees << @translation_decree
        @test_community.boards << @translation_board

        #set board order
        @meta_board.rank = 1
        @text_board.rank = 2
        @translation_board.rank = 3

        #mock an agent for agent based pass to test
        @agent = stub("mockagent")
        @client = stub("mockclient")
        @client.stubs(:post_content).raises(Exception)
        @client.stubs(:get_transformation).returns(nil)
        AgentHelper.stubs(:get_client).returns(@client)
        AgentHelper.stubs(:agent_of).returns(@agent)

        @test_agent_community = FactoryGirl.create(:pass_through_community,
                                             :name => "test_freaky_agent_community",
                                             :friendly_name => "testy agent",
                                             :allows_self_signup => true,
                                             #:abbreviation => "tc",
                                             :description => "a comunity for testing",
                                             :pass_to => "mockagent")

        @test_agent_community.members << @community_user
        @test_agent_board = FactoryGirl.create(:master_community_board, :title => "MockAgent", :community_id => @test_agent_community.id)
        @test_agent_board.users << @board_user_2
        @test_agent_decree = FactoryGirl.create(:count_decree,
                                          :board => @test_agent_board,
                                          :trigger => 1.0,
                                          :action => "approve",
                                          :choices => "ok")
        @test_agent_board.decrees << @test_agent_decree


        Rails.logger.debug "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz passthrouhh community testing setup complete zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
      end

      teardown do
        Rails.logger.debug "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx passhtrough community testing teardown begin xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        begin
          ActiveRecord::Base.connection_pool.with_connection do |conn|
            count = 0
            [ @board_user, @board_user_2, @creator_user, @master_user, @community_user, @test_community, @master_community, @test_agent_community ].each do |entity|
              count = count + 1
              #assert_not_equal entity, nil, count.to_s + " cant be destroyed since it is nil."
              unless entity.nil?
                entity.reload
                entity.destroy
              end
            end
          end
        end
        Rails.logger.debug "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz passhtrough community testing teardown complete zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
      end

      should "user creates and submits publication to community"  do
        Rails.logger.debug "BEGIN TEST: user creates and submits publication to community"

        assert_not_equal nil, @test_community, "Community not created"
        assert_equal "MasterCommunity", @test_community.pass_to_obj.class.name

        #create a publication with a session
        open_session do |publication_session|
          Rails.logger.debug "---Create A New Publication---"
          publication_session.post 'publications/create_from_templates' + '?test_user_id=' + @creator_user.id.to_s
          Rails.logger.debug "--flash is: " + publication_session.flash.inspect
          @publication = @creator_user.publications.first
          @publication.log_info
        end

        Rails.logger.debug "---Publication Created---"
        Rails.logger.debug "---Identifiers for publication " + @publication.title + " are:"

        @publication.identifiers.each do |pi|
          Rails.logger.debug "-identifier-"
          Rails.logger.debug "title is: " +  pi.title
          Rails.logger.debug "was it modified?: " + pi.modified?.to_s
        end

        #submit to the community
        Rails.logger.debug "---Submit Publication---"
        open_session do |submit_session|
          submit_session.post 'publications/' + @publication.id.to_s + '/submit/?test_user_id=' + @creator_user.id.to_s, :submit_comment => "I made a new pub", :community => { :id => @test_community.id.to_s }
          assert_equal "Publication submitted to #{@test_community.friendly_name}.", submit_session.flash[:notice]
          Rails.logger.debug "--flash is: " + submit_session.flash.inspect
        end
        @publication.reload

        #now meta should have it
        assert_equal "submitted", @publication.status, "Publication status not submitted " + @publication.community_id.to_s + " id "

        Rails.logger.debug "---Publication Submitted to Community: " + @publication.community.name

        #meta board should have 1 publication, others should have 0
        meta_publications = Publication.find(:all, :conditions => { :owner_id => @meta_board.id, :owner_type => "Board" } )
        assert_equal 1, meta_publications.length, "Meta does not have 1 publication but rather, " + meta_publications.length.to_s + " publications"

        text_publications = Publication.find(:all, :conditions => { :owner_id => @text_board.id, :owner_type => "Board" } )
        assert_equal 0, text_publications.length, "Text does not have 0 publication but rather, " + text_publications.length.to_s + " publications"

        translation_publications = Publication.find(:all, :conditions => { :owner_id => @translation_board.id, :owner_type => "Board" } )
        assert_equal 0, translation_publications.length, "Translation does not have 0 publication but rather, " + translation_publications.length.to_s + " publications"

        Rails.logger.debug "Community Meta Board has publication"

        #vote on it
        meta_publication = meta_publications.first

        #find meta identifier
        meta_identifier = nil
        meta_publication.identifiers.each do |id|
          if @meta_board.controls_identifier?(id)
            meta_identifier = id
          end
        end

        assert_not_nil  meta_identifier, "Did not find the meta identifier"
        Rails.logger.debug "Found meta identifier, will vote on it"

        #vote on meta publication
        open_session do |meta_session|
          meta_session.post 'publications/vote/' + meta_publication.id.to_s + '?test_user_id=' + @board_user.id.to_s, \
            :comment => { :comment => "I vote to agree meta is great", :user_id => @board_user.id, :publication_id => meta_identifier.publication.id, :identifier_id => meta_identifier.id, :reason => "vote" }, \
            :vote => { :publication_id => meta_identifier.publication.id.to_s, :identifier_id => meta_identifier.id.to_s, :user_id => @board_user.id.to_s, :board_id => @meta_board.id.to_s, :choice => "ok" }

          Rails.logger.debug "--flash is: " + meta_session.flash.inspect
          
        end
        
        #reload the publication to get the vote associations to go thru?
        meta_publication.reload

        vote_str = "Votes on meta are: "
        meta_publication.votes.each do |v|
          vote_str = vote_str + v.choice
        end
        Rails.logger.debug  vote_str

        assert_equal 1, meta_publication.votes.length, "Meta publication should have one vote"
        assert_equal 1, meta_publication.children.length, "Meta publication should have one child"

        #vote should have changed publication to approved and put to finalizer
        assert_equal "approved", meta_publication.status, "Meta publication not approved after vote"
        Rails.logger.debug "--Meta publication approved"

        #now finalizer should have it
        meta_final_publication = meta_publication.find_finalizer_publication

        assert_equal meta_final_publication.status, "finalizing", "Board user's publication is not for finalizing"
        Rails.logger.debug "---Meta Finalizer has publication"

        meta_final_identifier = nil
        meta_final_publication.identifiers.each do |id|
          if @meta_board.controls_identifier?(id)
            meta_final_identifier = id
          end
        end

        # do rename
        open_session do |meta_rename_session|
          meta_rename_session.put 'publications/' + meta_final_publication.id.to_s + '/hgv_meta_identifiers/' + meta_final_identifier.id.to_s + '/rename/?test_user_id='  + @board_user.id.to_s,
            :new_name => "papyri.info/hgv/#{Time.now.nsec}"
        end

        meta_final_publication.reload
        assert !meta_final_publication.needs_rename?, "finalizing publication should not need rename after being renamed"

        #finalize the meta
        open_session do |meta_finalize_session|

          meta_finalize_session.post 'publications/' + meta_final_publication.id.to_s + '/finalize/?test_user_id=' + @board_user.id.to_s, \
            :comment => 'I agree meta is great and now it is final'

          Rails.logger.debug "--flash is: " + meta_finalize_session.flash.inspect
          Rails.logger.debug "----session data is: " + meta_finalize_session.session.to_hash.inspect
          Rails.logger.debug meta_finalize_session.body
        end

        meta_final_publication.reload
        assert_equal "finalized", meta_final_publication.status, "Meta final publication not finalized"

        Rails.logger.debug "Meta committed"

        #compare the publications
        #you must look at the output to check the results of the comparisons
        #final and submitters' copy should have comments and votes
        Rails.logger.debug "++++++++USER PUBLICATION++++++"
        @creator_user.publications.first.log_info

        meta_publication.reload
        Rails.logger.debug "++++++++meta BOARD PUBLICATION++++++"
        meta_publication.log_info

        meta_final_publication.reload
        Rails.logger.debug "++++++++meta FINAL PUBLICATION++++++"
        meta_final_publication.log_info

        Rails.logger.debug "Compare board with board publication"
        compare_publications(meta_publication, meta_publication)
        Rails.logger.debug "Compare board with finalizer publication"
        compare_publications(meta_publication, meta_final_publication)

        Rails.logger.debug "Compare user with meta finalizer publication"
        compare_publications(@creator_user.publications.first, meta_final_publication)

        #meta testing complete

        #=================================TEXT BOARD==========================================
        #now text board should have it

        #meta board should have 1 publication
        meta_publications = Publication.find(:all, :conditions => { :owner_id => @meta_board.id, :owner_type => "Board" } )
        assert_equal 1, meta_publications.length, "Meta does not have 1 publication but rather, " + meta_publications.length.to_s + " publications"

        #text board should have 1 publication
        text_publications = Publication.find(:all, :conditions => { :owner_id => @text_board.id, :owner_type => "Board" } )
        assert_equal 1, text_publications.length, "Text does not have 0 publication but rather, " + text_publications.length.to_s + " publications"

        #translation board should have 0 publication
        translation_publications = Publication.find(:all, :conditions => { :owner_id => @translation_board.id, :owner_type => "Board" } )
        assert_equal 0, translation_publications.length, "Translation does not have 0 publication but rather, " + translation_publications.length.to_s + " publications"

        #vote on it
        text_publication = text_publications.first

        #find text identifier
        text_identifier = nil
        text_publication.identifiers.each do |id|
          if @text_board.controls_identifier?(id)
            text_identifier = id
          end
        end

        assert_not_nil  text_identifier, "Did not find the text identifier"

        Rails.logger.debug "Found text identifier, will vote on it"
        #vote on text
        open_session do |text_session|
          text_session.post 'publications/vote/' + text_publication.id.to_s + '?test_user_id=' + @board_user.id.to_s, \
            :comment => { :comment => "I vote since I yippppppp agree text is great", :user_id => @board_user.id, :publication_id => text_identifier.publication.id, :identifier_id => text_identifier.id, :reason => "vote" }, \
            :vote => { :publication_id => text_identifier.publication.id.to_s, :identifier_id => text_identifier.id.to_s, :user_id => @board_user.id.to_s, :board_id => @text_board.id.to_s, :choice => "ok" }
          Rails.logger.debug "--flash is: " + text_session.flash.inspect
        end

        #reload the publication to get the vote associations to go thru?
        text_publication.reload

        vote_str = "Votes on text are: "
        text_publication.votes.each do |v|
          vote_str = vote_str + v.choice
        end
        Rails.logger.debug  vote_str

        assert_equal 1, text_publication.votes.length, "Text publication should have one vote"
        Rails.logger.debug "After text publication voting, origin has children:"
        Rails.logger.debug text_publication.origin.children.inspect
        assert_equal 1, text_publication.children.length, "Text publication should have one child"

        #vote should have changed publication to approved and put to finalizer
        assert_equal "approved", text_publication.status, "Text publication not approved after vote"
        Rails.logger.debug "--Text publication approved"

        #now finalizer should have it, only one person on board so it should be them
        finalizer_publications = @board_user.publications
        assert_equal 2, finalizer_publications.length, "Finalizer does not have a new (text) publication to finalize"

        text_final_publication = text_publication.find_finalizer_publication
        assert_not_nil text_final_publication, "Publicaiton does not have text finalizer"
        Rails.logger.debug "---Finalizer has text publication"

        text_final_identifier = nil
        text_final_publication.identifiers.each do |id|
          if @text_board.controls_identifier?(id)
            text_final_identifier = id
          end
        end

        # do rename
        open_session do |text_rename_session|
          text_rename_session.put 'publications/' + text_final_publication.id.to_s + '/ddb_identifiers/' + text_final_identifier.id.to_s + '/rename/?test_user_id='  + @board_user.id.to_s,
            :new_name => "papyri.info/ddbdp/bgu;1;#{Time.now.nsec}", :set_dummy_header => false
        end

        text_final_publication.reload
        assert !text_final_publication.needs_rename?, "finalizing publication should not need rename after being renamed"

        #finalize text
        open_session do |text_finalize_session|
          text_finalize_session.post 'publications/' + text_final_publication.id.to_s + '/finalize/?test_user_id=' + @board_user.id.to_s, \
            :comment => 'I agree text is great and now it is final'

          Rails.logger.debug "--flash is: " + text_finalize_session.flash.inspect
          Rails.logger.debug "----session data from text finalize is:" + text_finalize_session.session.to_hash.inspect
          Rails.logger.debug text_finalize_session.body
          Rails.logger.debug "--flash is: " + text_finalize_session.flash.inspect
        end

        text_final_publication.reload
        assert_equal "finalized", meta_final_publication.status, "Text final publication not finalized"

        #text finalized
        Rails.logger.debug "---Text publication Finalized"

        #output results for visual inspection
        current_creator_publication = @creator_user.publications.first
        current_creator_publication.reload

        current_creator_publication.log_info

        meta_final_publication.reload
        meta_final_publication.log_info

        #text_final_publication.reload
        text_final_publication.log_info

        Rails.logger.debug "Compare user with text finalizer publication"
        compare_publications(@creator_user.publications.first, text_final_publication)

        # should now be submitted to the master board 
        @publication.reload
        assert_equal "submitted", @publication.status, "Publication status not resubmitted " + @publication.community_id.to_s + " id "
        Rails.logger.debug "---Publication Submitted to Community: " + @publication.community.name

        #master board should have 1 publication
        master_publications = Publication.find(:all, :conditions => { :owner_id => @master_board.id, :owner_type => "Board" } )
        assert_equal 1, master_publications.length, "Master does not have 1 publication but rather, " + master_publications.length.to_s + " publications"

        #vote on it
        master_publication = master_publications.first

        # board should have 2 identifiers (text and meta)
        master_identifiers = []
        master_publication.identifiers.each do |id|
          if @master_board.controls_identifier?(id)
             master_identifiers << id
          end
        end

        assert_equal 2, master_identifiers.length, "Master should have had 3 identifiers but has #{master_identifiers.length}"

        Rails.logger.debug "Vote on master"
        open_session do |master_session|
          master_session.post 'publications/vote/' + master_publication.id.to_s + '?test_user_id=' + @master_user.id.to_s, \
            :comment => { :comment => "I vote yes", :user_id => @master_user.id, :publication_id => master_publication.id, :identifier_id => master_identifiers[0].id, :reason => "vote" }, \
            :vote => { :publication_id => master_publication.id.to_s, :identifier_id => master_identifiers[0].id.to_s, :user_id => @master_user.id.to_s, :board_id => @master_board.id.to_s, :choice => "ok" }
          Rails.logger.debug "--flash is: " + master_session.flash.inspect
        end

        #reload the publication to get the vote associations to go thru?
        master_publication.reload

        vote_str = "Votes on master are: "
        master_publication.votes.each do |v|
          vote_str = vote_str + v.choice
        end
        assert_equal "approved", master_publication.status, "Master publication not approved after vote"
        Rails.logger.debug "--Master publication approved"

        #now finalizer should have it, only one person on board so it should be them
        finalizer_publications = @master_user.publications
        assert_equal 1, finalizer_publications.length, "Finalizer does not have a new (master) publication to finalize"

        master_final_publication = master_publication.find_finalizer_publication
        assert_not_nil master_final_publication, "Publicaiton does not have master finalizer"
        Rails.logger.debug "---Finalizer has master publication"

        master_final_identifiers = []
        master_final_publication.identifiers.each do |id|
          if @master_board.controls_identifier?(id)
            master_final_identifiers << id
          end
        end

        #finalize text
        open_session do |master_finalize_session|
          master_finalize_session.post 'publications/' + master_final_publication.id.to_s + '/finalize/?test_user_id=' + @master_user.id.to_s, \
            :comment => 'Finalized!'

          Rails.logger.debug "--flash is: " + master_finalize_session.flash.inspect
          Rails.logger.debug "----session data from master finalize is:" + master_finalize_session.session.to_hash.inspect
          Rails.logger.debug master_finalize_session.body
          Rails.logger.debug "--flash is: " + master_finalize_session.flash.inspect
        end

        master_final_publication.reload
        assert_equal "finalized", master_final_publication.status, "Text final publication not finalized"
        master_final_publication.identifiers.each do |id|
          assert_match /#{@board_user.name}">Vote/, id.content, "Vote not included in revDesc of finalized publication"
        end

        #text finalized
        Rails.logger.debug "---Master publication Finalized"

        Rails.logger.debug "Compare user with text finalizer publication"
        compare_publications(@creator_user.publications.first, text_final_publication)

        @publication.reload
        # original publication should now be committed
        assert_equal "committed", @publication.status, "Publication status not committed " + @publication.status
        Rails.logger.debug "---Publication Committed"

        @publication.destroy
    
        # @balmas this is all a bit of a hack to  test that the identifiers in the newly created and
        # finalized  publication are indeed committed to master -- I think since it's not going to
        # be in the numbers server we can't go through a controller method here 
        test_identifier_path = current_creator_publication.identifiers.first.to_path
        test_identifier_n = current_creator_publication.identifiers.first.n_attribute
        Rails.logger.debug "--- Checking master repository for " + test_identifier_path
        @publication = Publication.new()
        @publication.owner = @creator_user
        @publication.creator = @creator_user
        @publication.repository.update_master_from_canonical
        assert ! @publication.repository.get_file_from_branch(test_identifier_path, 'master').blank?
        @publication.destroy

        Rails.logger.debug "ENDED TEST: user creates and submits publication to pass through community"
      end

      should "also work with agent as pass to"  do
        Rails.logger.debug "BEGIN TEST: user creates and submits publication to pass through to agent community"

        assert_not_equal nil, @test_agent_community, "Community not created"
 
        #create a publication with a session
        open_session do |publication_session|
          Rails.logger.debug "---Create A New Publication---"
          publication_session.post 'publications/create_from_templates' + '?test_user_id=' + @creator_user.id.to_s
          Rails.logger.debug "--flash is: " + publication_session.flash.inspect
          @publication = @creator_user.publications.first
          @publication.log_info
        end

        Rails.logger.debug "---Publication Created---"
        Rails.logger.debug "---Identifiers for publication " + @publication.title + " are:"

        @publication.identifiers.each do |pi|
          Rails.logger.debug "-identifier-"
          Rails.logger.debug "title is: " +  pi.title
          Rails.logger.debug "was it modified?: " + pi.modified?.to_s
        end

        #submit to the community
        Rails.logger.debug "---Submit Publication---"
        open_session do |submit_session|
          submit_session.post 'publications/' + @publication.id.to_s + '/submit/?test_user_id=' + @creator_user.id.to_s, :submit_comment => "I made a new pub", :community => { :id => @test_agent_community.id.to_s }
          assert_equal "Publication submitted to #{@test_agent_community.friendly_name}.", submit_session.flash[:notice]
          Rails.logger.debug "--flash is: " + submit_session.flash.inspect
        end
        @publication.reload

        #now meta should have it
        assert_equal "submitted", @publication.status, "Publication status not submitted " + @publication.community_id.to_s + " id "

        Rails.logger.debug "---Publication Submitted to Community: " + @publication.community.name

        #agent board should have 1 publication, others should have 0
        agent_publications = Publication.find(:all, :conditions => { :owner_id => @test_agent_board.id, :owner_type => "Board" } )
        assert_equal 1, agent_publications.length, "Meta does not have 1 publication but rather, " + agent_publications.length.to_s + " publications"

        Rails.logger.debug "Community Agent Board has publication"

        #vote on it
        agent_publication = agent_publications.first

        #find identifier
        agent_identifiers = []
        agent_publication.identifiers.each do |id|
          if @test_agent_board.controls_identifier?(id)
            agent_identifiers << id
          end
        end

        assert_equal 2,  agent_identifiers.length, "Did not have the agent identifiers"
        Rails.logger.debug "Found agent identifier, will vote on it"

        #vote on meta publication
        open_session do |agent_session|
          agent_session.post 'publications/vote/' + agent_publication.id.to_s + '?test_user_id=' + @board_user_2.id.to_s, \
            :comment => { :comment => "I vote", :user_id => @board_user_2.id, :publication_id => agent_publication.id, :identifier_id => agent_identifiers[0].id, :reason => "vote" }, \
            :vote => { :publication_id => agent_publication.id.to_s, :identifier_id => agent_identifiers[0].id.to_s, :user_id => @board_user_2.id.to_s, :board_id => @test_agent_board.id.to_s, :choice => "ok" }

          Rails.logger.debug "--flash is: " + agent_session.flash.inspect
          
        end
        
        #reload the publication to get the vote associations to go thru?
        agent_publication.reload

        vote_str = "Votes on meta are: "
        agent_publication.votes.each do |v|
          vote_str = vote_str + v.choice
        end
        Rails.logger.debug  vote_str

        assert_equal 1, agent_publication.votes.length, "Meta publication should have one vote"

        #vote should have changed publication to approved and put to finalizer
        assert_equal "approved", agent_publication.status, "Meta publication not approved after vote"
        Rails.logger.debug "--Agent publication approved"

        #now finalizer should have it
        agent_final_publication = agent_publication.find_finalizer_publication

        assert_equal agent_final_publication.status, "finalizing", "Board user's publication is not for finalizing"
        Rails.logger.debug "---Agent Finalizer has publication"

        agent_final_identifiers = []
        agent_final_publication.identifiers.each do |id|
          if @test_agent_board.controls_identifier?(id)
            agent_final_identifiers << id
          end
        end

        # do rename
        open_session do |agent_rename_session|
          agent_rename_session.put 'publications/' + agent_final_publication.id.to_s + '/ddb_identifiers/' + agent_final_identifiers[0].id.to_s + '/rename/?test_user_id='  + @board_user_2.id.to_s,
            :new_name => "papyri.info/ddbdp/bgu;1;#{Time.now.nsec}.", :set_dummy_header => false
        end
        open_session do |agent_rename_session|
          agent_rename_session.put 'publications/' + agent_final_publication.id.to_s + '/hgv_meta_identifiers/' + agent_final_identifiers[1].id.to_s + '/rename/?test_user_id='  + @board_user_2.id.to_s,
            :new_name => "papyri.info/hgv/#{Time.now.nsec}"
        end

        agent_final_publication.reload
        assert !agent_final_publication.needs_rename?, "finalizing publication should not need rename after being renamed"

        finalizer_publications = @board_user_2.publications
        assert_equal 1, finalizer_publications.length, "Finalizer does not have publication to finalize"

        # at first, test with mock agent as setup to fail to be sure finalization fails and publication is left in finalizing state
        open_session do |agent_finalize_session|
          agent_finalize_session.post 'publications/' + agent_final_publication.id.to_s + '/finalize/?test_user_id=' + @board_user_2.id.to_s, \
            :comment => 'I agree text is great and now it is final'

          Rails.logger.debug "--flash is: " + agent_finalize_session.flash.inspect
          Rails.logger.debug "----session data from text finalize is:" + agent_finalize_session.session.to_hash.inspect
          assert_not_nil agent_finalize_session.flash[:error]
          assert_not_equal "", agent_finalize_session.flash[:error]
        end

        finalizer_publications = @board_user_2.publications
        assert_equal 1, finalizer_publications.length, "Finalizer does not still have a publication to finalize"

        agent_final_publication = agent_publication.find_finalizer_publication
        assert_not_nil agent_final_publication, "Publicaiton does not still have finalizer"
        Rails.logger.debug "---Finalizer still has publication"

        @client.stubs(:post_content).returns(201)
        #now really finalize text
        open_session do |agent_finalize_session|
          agent_finalize_session.post 'publications/' + agent_final_publication.id.to_s + '/finalize/?test_user_id=' + @board_user_2.id.to_s, \
            :comment => 'I agree text is great and now it is final'

          Rails.logger.debug "--flash is: " + agent_finalize_session.flash.inspect
          Rails.logger.debug "----session data from finalize is:" + agent_finalize_session.session.to_hash.inspect
          Rails.logger.debug agent_finalize_session.body
          Rails.logger.debug "--flash is: " + agent_finalize_session.flash.inspect
        end


        agent_final_publication.reload
        agent_final_publication.log_info
        assert_equal "finalized", agent_final_publication.status, "Text final publication not finalized"

        #text finalized
        Rails.logger.debug "---Agent publication Finalized"

        #output results for visual inspection
        current_creator_publication = @creator_user.publications.first
        current_creator_publication.reload

        current_creator_publication.log_info

        Rails.logger.debug "Compare user with text finalizer publication"
        compare_publications(@creator_user.publications.first, agent_final_publication)

        # should now be commited
        @publication.reload
        assert_equal "committed", @publication.status, "Publication status not committed " + @publication.community_id.to_s + " id "
        Rails.logger.debug "---Publication Submitted to Community: " + @publication.community.name

        #master board should have 0 publication
        master_publications = Publication.find(:all, :conditions => { :owner_id => @master_board.id, :owner_type => "Board" } )
        assert_equal 0, master_publications.length, "Master does not have 1 publication but rather, " + master_publications.length.to_s + " publications"

        # verify that we can resend to the agent after finalization if need be
        open_session do |resend_session|
          get "publications/#{agent_final_publication.id.to_s}/send_to_agent?&test_user_id=#{@board_user_2.id.to_s}"
          assert_response :redirect
          assert_equal "Publication resent to agent.", flash[:notice]
        end

        Rails.logger.debug "ENDED TEST: user creates and submits publication to pass through to agent community"
      end
    end
  end
end
