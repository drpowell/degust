class DeSettingsController < ApplicationController
    def new
    end

    def show
        redirect_to degust_compare_url(params['version'], params['id'])
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

        redirect_to degust_compare_url('', @de_setting.secure_id)
    end

    def copy
        de_setting = DeSetting.find_by_secure_id(params[:id])
        if current_user.nil? || de_setting.nil?
            redirect_to :back, :alert => "Access denied!"
        else
            new_de = de_setting.dup
            new_de.randomize_id()
            new_de.user = current_user
            new_de.set_name("COPY : "+new_de.name)
            new_de.save!
            redirect_to visited_path

        end
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
            respond_to do |format|
                format.html { redirect_to root_path }
                format.json { render :json => { :redirect => root_path } }
            end
        else
            @mine = current_user.de_settings
            @others = Visited.where(:user => current_user).map(&:de_setting).select {|de| de.user != current_user}

            respond_to do |format|
                format.html
                format.json { render :json => { :mine => @mine, :others => @others } }
            end
        end
    end
end
