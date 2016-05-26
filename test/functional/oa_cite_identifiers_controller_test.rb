require 'test_helper'

class OaCiteIdentifiersControllerTest < ActionController::TestCase

  def setup 
    @user = FactoryGirl.create(:user)
    @user2 = FactoryGirl.create(:user)
    @request.session[:user_id] = @user.id
    @publication = FactoryGirl.create(:publication, :owner => @user, :creator => @user, :status => "new")
    @publication.branch_from_master

    # use a mock Google agent so test doesn't depend upon live google doc
    # test document should produce 9 annotations (from 6 entries in the spreadsheet)
    @client = stub("googless")
    @client.stubs(:get_content).returns(File.read(File.join(File.dirname(__FILE__), '../unit/data', 'google1.xml')))
    @client.stubs(:get_transformation).returns("/data/xslt/cite/gs_to_oa_cite.xsl")
    AgentHelper.stubs(:get_client).returns(@client)
    
  end

  def teardown
    @publication.destroy
    @user.destroy
    @user2.destroy
  end

  test "should get import" do
    get :import
    assert_response :success
  end

  test "should get import_update" do
    init_value = ["https://docs.google.com/spreadsheet/pub?key=0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc&output=html"]
    @identifier = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
    # TODO we need an identifier
    get :import_update, :id => @identifier.id.to_s
    assert_response :success
  end

  test "should get edit view without edit links" do
    init_value = ["https://docs.google.com/spreadsheet/pub?key=0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc&output=html"]
    @identifier = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
    get :edit, :id => @identifier.id.to_s, :publication_id => @identifier.publication.id.to_s
    assert_response :success
    assert_select 'div.oa_cite_annotation' do 
      # we shouldn't have any edit buttons in this view because the annotations are from an external agent
      assert_select 'div.edit_links>a', 0
    end
  end

  test "should get edit view with edit links" do
    @identifier = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
    @identifier.create_annotation("http://test.host/cts/getpassage/1/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1")
    get :edit, :id => @identifier.id.to_s, :publication_id => @identifier.publication.id.to_s
    assert_response :success
    assert_select 'div.oa_cite_annotation' do 
      # we should have edit links and delete button in this view because the annotations are from a native client
      assert_select 'div.edit_links>a', 1
      assert_select 'button[type=submit]', 1
    end
  end

  test "should get preview without preview_links" do
    init_value = ["https://docs.google.com/spreadsheet/pub?key=0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc&output=html"]
    @identifier = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
    get :preview, :id => @identifier.id.to_s, :publication_id => @identifier.publication.id.to_s
    assert_response :success
    assert_select 'div.oa_cite_annotation' do 
      # we shouldn't have any edit options in this view
      assert_select 'div.edit_links>a', 0
    end
  end

  test "should get preview with preview_links" do
    @identifier = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
    @identifier.create_annotation("http://test.host/cts/getpassage/1/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1")
    get :preview, :id => @identifier.id.to_s, :publication_id => @identifier.publication.id.to_s
    assert_response :success
    assert_select 'div.oa_cite_annotation' do 
      assert_select 'div.edit_links' do
        # we should have preview links
        assert_select 'a', 1
        # we should not have any edit buttons
        assert_select 'button[type=submit]', 0
      end
    end
  end

  test "edit with annotation_uri" do
    @identifier = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
    @identifier.create_annotation("http://localhost/cts/getpassage/1/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1")
    get :edit, :id => @identifier.id.to_s, :publication_id => @identifier.publication.id.to_s, :annotation_uri => "http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#1"
    assert_redirected_to( "http://localhost/annotation-editor/perseids-annotate.xhtml?uri=http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/%231&lang=LANG&doc=#{@identifier.id.to_s}")
  end

  test "should get editxml view" do
    @identifier = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
    @identifier.create_annotation("http://localhost/cts/getpassage/1/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1")
    get :editxml, :id => @identifier.id.to_s, :publication_id => @identifier.publication.id.to_s
    assert_response :success
    assert_select 'textarea#oa_cite_identifier_xml_content', 1
  end

  test "should process delete annotation" do
    @identifier = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
    @identifier.create_annotation("http://localhost/cts/getpassage/1/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1")
    post :delete_annotation, :publication_id => @identifier.publication.id.to_s,  :id => @identifier.id.to_s, :annotation_uri => "http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#1"
    assert_equal "Annotation Deleted", flash[:notice]
    assert_redirected_to edit_publication_oa_cite_identifier_path( @identifier.publication, @identifier ) 
    post :delete_annotation, :publication_id => @identifier.publication.id.to_s,  :id => @identifier.id.to_s, :annotation_uri => "http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#1"
    assert_equal "Annotation http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#1 not found", flash[:error]
    assert_redirected_to preview_publication_oa_cite_identifier_path( @identifier.publication, @identifier )
  end

  test "enforce ownership on delete annotation" do
    @identifier = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
    @identifier.create_annotation("http://localhost/cts/getpassage/1/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1")
    @request.session[:user_id] = @user2.id
    post :delete_annotation, :publication_id => @identifier.publication.id.to_s,  :id => @identifier.id.to_s, :annotation_uri => "http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#1"
    assert_equal "Operation not permitted.", flash[:error]
    assert_redirected_to( dashboard_url )
  end

  test "create" do 
    assert_difference('OaCiteIdentifier.count') do
      post :create, :publication_id => @publication.id.to_s, :collection_urn => 'urn:cite:perseus:pdlann'
    end
    assert_not_nil assigns(:identifier)
    assert_redirected_to edit_publication_oa_cite_identifier_path( @publication, assigns(:identifier) )
  end

  test "enforce ownership on create" do 
    @request.session[:user_id] = @user2.id
    post :create, :publication_id => @publication.id.to_s, :collection_urn => 'urn:cite:perseus:pdlann'
    assert_equal "Operation not permitted.", flash[:error]
    assert_redirected_to( dashboard_url )
  end

  test "edit_or_create should create a new annotation document" do
    target_uri = "http://test.host/cts/getpassage/1/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1"
    assert_difference('OaCiteIdentifier.count') do
      post :edit_or_create, :publication_id => @publication.id.to_s, :collection_urn => 'urn:cite:perseus:pdlann', :target_uri => target_uri
    end
    # test that we're redirected to edit the new annotation
    assert_redirected_to edit_publication_oa_cite_identifier_path( @publication, assigns(:identifier), :annotation_uri => 'http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#1' )
  end 

  test "edit_or_create should display append" do
    @identifier = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
    target_uri = "http://test.host/cts/getpassage/1/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1"
    @identifier.create_annotation(target_uri)
    assert_difference('OaCiteIdentifier.count',0) do
      post :edit_or_create, :publication_id => @publication.id.to_s, :collection_urn => 'urn:cite:perseus:pdlann', :target_uri => target_uri
    end 
    assert_response :success
    assert_select 'div#append_annotation' do
      # should be offered submit button to append a new annotation
      assert_select 'input[type=submit]', 1
      # should be offered link to edit the existing annotation
      assert_select '#existing_annotations' do
        assert_select 'a', 1
      end
    end
  end 

  # in theory this shouldn't be possible to create 2 oa_cite_identifiers on the same publication
  # through the UI - this test catches the error that happens if this check is somehow circumvented
  test "edit_or_create should raise error creating a duplicate annotation document" do
    @identifier = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
    target_uri = "http://test.host/cts/getpassage/1/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1"
    @identifier.create_annotation(target_uri)
    @identifier = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
    target_uri = "http://test.host/cts/getpassage/1/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1"
    @identifier.create_annotation(target_uri)
    assert_difference('OaCiteIdentifier.count',0) do
      post :edit_or_create, :publication_id => @publication.id.to_s, :collection_urn => 'urn:cite:perseus:pdlann', :target_uri => target_uri
    end
    assert_match /more than one oaciteidentifier/, flash[:error]
    assert_redirected_to dashboard_url
  end 

  test "enforce ownership on edit_or_create" do 
    @request.session[:user_id] = @user2.id
    post :edit_or_create, :publication_id => @publication.id.to_s, :collection_urn => 'urn:cite:perseus:pdlann', :target_uri => "http://example.org"
    assert_equal "Operation not permitted.", flash[:error]
    assert_redirected_to( dashboard_url )
  end

  test "append_annotation should update the document" do
    assert_difference('OaCiteIdentifier.count') do
      post :create, :publication_id => @publication.id.to_s, :collection_urn => 'urn:cite:perseus:pdlann'
    end
    assert_not_nil assigns(:identifier)
    @identifier = assigns(:identifier)
    assert_difference('OaCiteIdentifier.count',0) do
      post :append_annotation, :id => @identifier.id.to_s, :target_uri => "http://example.org"
    end 
    assert_equal "Annotation added", flash[:notice]
    assert_not_nil @identifier.get_annotation("http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#1")
    assert_redirected_to edit_publication_oa_cite_identifier_path( @publication, @identifier, :annotation_uri => 'http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#1' )
  end

  test "enforce_ownership on append_annotation" do
    assert_difference('OaCiteIdentifier.count') do
      post :create, :publication_id => @publication.id.to_s, :collection_urn => 'urn:cite:perseus:pdlann'
    end
    @identifier = assigns(:identifier)
    assert_not_nil @identifier
    @request.session[:user_id] = @user2.id
    assert_difference('OaCiteIdentifier.count',0) do
      post :append_annotation, :id => @identifier.id.to_s, :target_uri => "http://example.org"
    end 
    @identifier.reload
    assert_nil @identifier.get_annotation("http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#1")
    assert_equal "Operation not permitted.", flash[:error]
    assert_redirected_to( dashboard_url )
  end

  test "update_from_agent" do
    @identifier = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
    post :update_from_agent, :id => @identifier.id.to_s, :agent_url => "https://docs.google.com/spreadsheet/pub?key=0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc&output=html"
    assert_not_nil @identifier.get_annotation("http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#1-1")
    assert_redirected_to publication_path @identifier.publication
  end

  test "enforce_ownership on update_from_agent" do
    @identifier = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
    @request.session[:user_id] = @user2.id
    post :update_from_agent, :id => @identifier.id.to_s, :agent_url => "https://docs.google.com/spreadsheet/pub?key=0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc&output=html"
    assert_nil @identifier.get_annotation("http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#1")
    assert_equal "Operation not permitted.", flash[:error]
    assert_redirected_to( dashboard_url )
  end

  test "convert with create" do 
    # TODO - should test this but we may not keep it
  end

  test "enforce ownership on convert" do 
    # TODO - should test this but we may not keep it
  end

  test "convert without create " do 
    # TODO - should test this but we may not keep it
  end

  test "convert without create json format " do 
    # TODO - should test this but we may not keep it
  end

  test "destroy" do
    @identifier = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
    @identifier2 = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
    assert_difference('OaCiteIdentifier.count',-1) do
      delete :destroy, :id => @identifier2.id.to_s
    end
    assert_redirected_to publication_path(@publication)
    assert_difference('OaCiteIdentifier.count',0) do
      delete :destroy, :id => @identifier.id.to_s
    end
    assert_equal "This would leave the publication without any identifiers.", flash[:error]
    assert_redirected_to publication_path(@publication)
  end

  test "enforce ownership on destroy" do
    @identifier = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
    @request.session[:user_id] = @user2.id
    assert_difference('OaCiteIdentifier.count',0) do
      delete :destroy, :id => @identifier.id.to_s
    end
    assert_equal "Operation not permitted.", flash[:error]
    assert_redirected_to( dashboard_url )
  end

    # TODO IMPORT SCENARIOS
     #should "new_from_template works with gss key pub url as init_value" do
      #  init_value = ["https://docs.google.com/spreadsheet/pub?key=0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc&output=html"]
      #  test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
      #  assert_not_nil test
      #  assert_equal 9, test.get_annotations().size
      #end
      #should "new_from_template works with gss key link url as init_value" do
      #  init_value = ["https://docs.google.com/spreadsheet/ccc?key=0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc&usp=sharing"]
      #  test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
      #  assert_not_nil test
      #  assert_equal 9, test.get_annotations().size
      #end
      #should "new_from_template work with gss pub url as init_value" do
      #  init_value = ["https://docs.google.com/spreadsheets/d/0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc/pubhtml"]
      #  test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
      #  assert_not_nil test
      #  assert_equal 9, test.get_annotations().size
      #end

      #should "new_from_template should work with gss link url as init_value" do
      #  init_value = ["https://docs.google.com/spreadsheets/d/0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc/edit?usp=sharing"]
      #  test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
      #  assert_not_nil test
      #  assert_equal 9, test.get_annotations().size
      #end

      #should "new_from_template raises error with invalid google url as init_value" do
      #  init_value = ["https://docs.google.com/spreadsheets/d/0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc"]
      #  @client.stubs(:get_content).raises("Invalid URL")
      #  exception = assert_raises(RuntimeError) {
      #    test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
      #  }

end
