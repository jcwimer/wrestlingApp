require 'test_helper'

class WrestlersControllerTest < ActionController::TestCase
  setup do
    @wrestler = wrestlers(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:wrestlers)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create wrestler" do
    assert_difference('Wrestler.count') do
      post :create, wrestler: { name: @wrestler.name, original_seed: @wrestler.original_seed, school_id: @wrestler.school_id, seed: @wrestler.seed, weight_id: @wrestler.weight_id }
    end

    assert_redirected_to wrestler_path(assigns(:wrestler))
  end

  test "should show wrestler" do
    get :show, id: @wrestler
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @wrestler
    assert_response :success
  end

  test "should update wrestler" do
    patch :update, id: @wrestler, wrestler: { name: @wrestler.name, original_seed: @wrestler.original_seed, school_id: @wrestler.school_id, seed: @wrestler.seed, weight_id: @wrestler.weight_id }
    assert_redirected_to wrestler_path(assigns(:wrestler))
  end

  test "should destroy wrestler" do
    assert_difference('Wrestler.count', -1) do
      delete :destroy, id: @wrestler
    end

    assert_redirected_to wrestlers_path
  end
end
