class DeSettingsController < ApplicationController
    # Skip verifying csrf to allow command line uploads.  This will be checked in the method below
    skip_before_action :verify_authenticity_token, :only => [:create]


    def show
        redirect_to degust_compare_url(params['version'], params['id'])
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

        # Create the DeSetting object
        @de_setting = DeSetting.new()
        @de_setting.user_file = @user_file
        @de_setting.user = user

        # If there are settings from the user, use those as default
        if params['settings']
            new_settings = JSON.parse(params['settings'])
            ok = @de_setting.update_from_json(new_settings)
            if !ok
                render status: 400, plain: 'Invalid character in field'
                return
            end
        end
        @de_setting.save!

        redirect_to degust_page_path("compare.html")+"?code="+@de_setting.secure_id
    end

    def copy
        de_setting = DeSetting.find_by_secure_id(params[:id])
        if current_user.nil? || de_setting.nil?
            redirect_back :fallback_location => root_path, :alert => "Access denied!"
        else
            new_de = de_setting.dup
            new_de.randomize_id()
            new_de.user = current_user
            new_de.set_name("COPY : "+new_de.name)
            new_de.save!
            redirect_to degust_compare_url('', new_de.secure_id)

        end
    end

    def destroy
        de_setting = DeSetting.find_by_secure_id(params[:id])
        if !current_user.nil? && de_setting.user == current_user
            Visited.where(:de_setting => de_setting).map {|v| v.destroy}
            de_setting.destroy
            redirect_back :fallback_location => root_path, :alert => "Data deleted!"
        else
            redirect_back :fallback_location => root_path, :alert => "Access denied!"
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
