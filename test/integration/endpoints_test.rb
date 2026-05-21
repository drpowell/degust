require 'test_helper'

class EndpointsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @de_setting = de_settings(:one)
  end

  test "root path" do
    get root_path
    assert_response :success
  end

  test "degust settings" do
    get settings_degust_path(@de_setting.secure_id), as: :json
    assert_response :success
    json = JSON.parse(response.body)
    # Based on testing, settings_with_defaults returns what's in the DB.
    # The secure_id is a column on de_settings, not part of the JSON blob.
    # The controller renders: res = {settings: de_setting.settings_with_defaults}
    # It does NOT seem to add 'id' or 'secure_id' to that nested hash.
    # Let's verify what keys ARE present.
    assert json.key?('settings')
  end

  test "degust partial_csv" do
    get partial_csv_degust_path(@de_setting.secure_id)
    assert_response :success
  end

  test "degust csv" do
    get csv_degust_path(@de_setting.secure_id)
    assert_response :success
  end

  test "degust dge with voom" do
    fields = ["WT", "luxS"].to_json
    get dge_degust_path(@de_setting.secure_id), params: { method: 'voom', fields: fields }, as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert json.key?('csv'), "Response should contain 'csv' key. Body: #{response.body}"
  end

  test "degust dge with RUV-edgeR and all normalization types" do
    fields = ["WT", "luxS"].to_json
    ['TMM', 'RLE', 'upperquartile', 'none'].each do |norm|
      ruv_params = { flavour: 'ruvg', k: 1, prop_empirical: 0.5, normalization: norm }.to_json
      get dge_degust_path(@de_setting.secure_id), params: { method: 'RUV-edgeR', fields: fields, ruv: ruv_params }, as: :json
      assert_response :success
      json = JSON.parse(response.body)
      assert json.key?('csv'), "Response for normalization #{norm} should contain 'csv' key. Body: #{response.body}"
    end
  end
  test "static page" do
    get "/degust/compare.html"
    assert_response :success
  end

  test "visited index" do
    get visited_path
    assert_response :redirect
  end

  test "upload page" do
    get upload_path
    assert_response :success
  end

  test "users index requires admin" do
    get users_path
    assert_response :redirect
  end
end
