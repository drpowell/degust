class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user
  helper_method :user_signed_in?
  helper_method :correct_user?

  private
    def current_user
      begin
        @current_user ||= User.find(session[:user_id]) if session[:user_id]
      rescue Exception => e
        nil
      end
    end

    def user_signed_in?
      return true if current_user
    end

    def correct_user?
      if params[:id] == 'me'
        @user = current_user
      else
        @user = User.find(params[:id])
      end
      unless current_user == @user || (!current_user.nil? && current_user.admin?)
        redirect_to root_url, :alert => "Access denied."
      end
    end

    def authenticate_user!
      if !current_user
        redirect_to root_url, :alert => 'You need to sign in for access to this page.'
      end
    end

    # Return the URL for the give version and secure_id
    # An empty version string should go to the canonical url, which should map to an older stable build
    def degust_compare_url(version, id)
      if version==''
        degust_page_path("compare.html")+"?code=#{id}"
      else
        degust_page_version_path(version, "compare.html")+"?code=#{id}"
      end
    end

    # Return the actual directory for the frontend code for the given version
    # An empty version string should go to the canonical url, which should map to an older stable build
    # Note the special handling of 'dev' to go to the current build
    def dir_for_version(version)
      case version
      when ''
        "degust-frontend/degust-dist-3.1"
      when 'dev'
        "degust-frontend/degust-dist"
      else
        "degust-frontend/degust-dist-#{version}"
      end
    end

    def frontend_versions
      ['3.1', 'dev']
    end
    helper_method :frontend_versions, :dir_for_version, :degust_compare_url

end
