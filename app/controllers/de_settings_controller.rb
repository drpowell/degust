class DeSettingsController < ApplicationController
  def new
  end

  def show
      redirect_to('/degust/compare.html?code='+params['id'])
  end

  def create
    f = params['filename']
    @user_file = UserFile.create()
    @user_file.from_tempfile(f)
    @user_file.save!

    @de_setting = DeSetting.new()
    @de_setting.user_file = @user_file
    @de_setting.user = current_user
    @de_setting.save!

    redirect_to '/degust/compare.html?code='+@de_setting.secure_id
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
