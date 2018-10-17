class DeSettingsController < ApplicationController

  # Skip verifying csrf to allow command line uploads.  This will be checked in the method below
  skip_before_action :verify_authenticity_token, :only => [:create]

  def new
  end

  def show
      redirect_to degust_page_path("compare.html")+"?code="+params['id']
  end

  def create
    # Either valid upload token OR CSRF tags
    tok = params['upload_token']
    if tok.nil? || !tok
        user = current_user
        verify_authenticity_token
    else
        user = User.find_by_upload_token(tok)
        if user.nil?
            render status: 400, plain: 'Access denied'
            return
        end
    end

    # All valid, create the file.
    f = params['filename']
    @user_file = UserFile.create()
    @user_file.from_tempfile(f)
    @user_file.save!

    @de_setting = DeSetting.new()
    @de_setting.user_file = @user_file
    @de_setting.user = user
    @de_setting.save!

    redirect_to degust_page_path("compare.html")+"?code="+@de_setting.secure_id
  end

  def destroy
      de_setting = DeSetting.find_by_secure_id(params[:id])
      if !current_user.nil? && de_setting.user == current_user
          Visited.where(:de_setting => de_setting).map {|v| v.destroy}
          de_setting.destroy
          redirect_to :back, :alert => "Data deleted!"
      else
          redirect_to :back, :alert => "Access denied!"
      end
  end

  def index
      if current_user.nil?
          redirect_to root_path
      else
          @mine = current_user.de_settings
          @others = Visited.where(:user => current_user).map(&:de_setting).select {|de| de.user != current_user}
      end
  end

end
