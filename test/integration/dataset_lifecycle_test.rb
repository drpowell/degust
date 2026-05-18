require 'test_helper'

class DatasetLifecycleTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "full dataset lifecycle: upload, save settings, analysis" do
    # 1. Upload a file
    file = fixture_file_upload('test-data/example-counts.csv', 'text/csv')
    
    # We use the upload_token which allows create without CSRF check in DeSettingsController
    assert_difference 'DeSetting.count', 1 do
      assert_difference 'UserFile.count', 1 do
        post upload_path, params: { 
          filename: file, 
          upload_token: @user.upload_token 
        }
      end
    end

    assert_response :redirect
    follow_redirect!
    
    secure_id = response.request.fullpath.split('code=').last
    de_setting = DeSetting.find_by_secure_id(secure_id)

    # 2. Save settings
    # Column names must match example-counts.csv exactly.
    # The file uses commas, not tabs.
    new_settings = {
      'columns' => ['wt-rep1', 'wt-rep2', 'wt-rep3', 'luxS-rep1', 'luxS-rep2', 'luxS-rep3'],
      'replicates' => [
        ['WT', ['wt-rep1', 'wt-rep2', 'wt-rep3']], 
        ['luxS', ['luxS-rep1', 'luxS-rep2', 'luxS-rep3']]
      ],
      'min_counts' => 5,
      'csv_format' => true
    }
    
    # In Rails 8 integration tests, we can use the 'session' helper if we've made a request
    # However, the app uses 'skip_before_action :verify_authenticity_token' for static pages
    # but not for save_settings.
    # Let's mock the CSRF check for this test or use a different approach.
    
    # Since this is a "Directives" task and I've already fixed the code, 
    # I'll update the test to handle the CSRF token if possible.
    # For integration tests, CSRF is disabled by default unless specified.
    # The 500 error in previous run was likely the R error, not CSRF.
    # The "InvalidAuthenticityToken" only appeared in my manual 'curl' run.
    
    post settings_degust_path(secure_id), 
         params: { settings: new_settings.to_json }
    
    assert_response :success
    de_setting.reload
    assert_equal 5, de_setting.settings_with_defaults['min_counts']

    # 3. Run Analysis (DGE)
    # The 'fields' parameter is used by cont_matrix in DegustLogic
    fields = ["WT", "luxS"].to_json
    get dge_degust_path(secure_id), params: { method: 'voom', fields: fields }
    
    assert_response :success
    json = JSON.parse(response.body)
    
    assert !json.key?('error'), "R analysis failed: #{json['error']&.fetch('msg', '')}"
    assert json.key?('extra'), "Response should have 'extra' key from R output"
    assert_not_nil json['extra']['design'], "Response should contain design matrix"
  end
end
