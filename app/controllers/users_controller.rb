class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :correct_user?, :except => [:index]

  def index
    if current_user.admin?
      @users = User.all
    else
      redirect_to root_url, :alert => "Access denied."
    end
  end

  def show
    @user = User.find(params[:id])
  end

end
