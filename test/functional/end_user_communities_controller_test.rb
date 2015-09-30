require 'test_helper'

class EndUserCommunitiesControllerTest < ActionController::TestCase

  def setup 
    @admin = FactoryGirl.create(:admin)
    @request.session[:user_id] = @admin.id
    @community = FactoryGirl.create(:end_user_community)
    @community_two = FactoryGirl.create(:end_user_community)
  end

  def teardown
    @request.session[:user_id] = nil
    @admin.destroy
    @community.destroy unless !Community.exists? @community.id
    @community_two.destroy unless !Community.exists? @community_two.id
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:communities)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create end_user_community" do
    assert_difference('EndUserCommunity.count') do
      post :create, :end_user_community => FactoryGirl.build(:end_user_community).attributes.merge({"admins"=>[],"members"=>[]})
    end

    assert_redirected_to edit_end_user_community_path(assigns(:community))
  end

  test "should show end_user_community" do
    get :show, id: @community
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @community
    assert_response :success
  end

  test "should update end_user_community" do
    put :update, id: @community, end_user_community: {  }
    assert_redirected_to edit_end_user_community_path(assigns(:community))
  end

  test "should destroy end_user_community" do
    assert_difference('EndUserCommunity.count', -1) do
      delete :destroy, id: @community
    end

    assert_redirected_to :controller => 'user', :action => 'admin'
  end
end
