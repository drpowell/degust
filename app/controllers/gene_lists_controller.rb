class GeneListsController < ApplicationController
    def index
        #de_setting = DeSetting.find_by_secure_id(params[:id])
        genelists = GeneList.where(:de_setting_id => params[:id]).select([:title, :description])
        render json: genelists
    end

    def show
        gene_list = GeneList.find_by_id(params[:gene_list_id])
        render json: gene_list
    end

    def create
        de_setting = DeSetting.find_by_secure_id(params[:id])
        if !de_setting.can_modify(current_user)
            render status: 400, plain: 'Access denied : locked'
            return
        end

        @gene_list = GeneList.new()
        @gene_list.user = current_user
        @gene_list.de_settings = params[:id]

        @gene_list.title = params[:title]
        @gene_list.description = params[:description]
        @gene_list.id_type = params[:id_type]
        @gene_list.columns = params[:columns]
        @gene_list.rows = params[:rows]
        @gene_list.save!
    end

    def destroy
        de_setting = DeSetting.find_by_secure_id(params[:id])
        genelist = de_settings.find_by_id(params[:gene_list_id])
        if !current_user.nil? && de_setting.user == current_user && genelist.de_setting==de_setting
            genelist.destroy
            redirect_to :back, :alert => "Gene List deleted!"
        else
            redirect_to :back, :alert => "Access denied!"
        end
    end

end
