class GeneListsController < ApplicationController
    def index
        de_setting = DeSetting.find_by_secure_id(params[:id])
        gene_lists = GeneList.where(:de_setting_id => de_setting.id).select([:id, :title, :description, :id_type])
        render json: gene_lists
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
        @gene_list.de_setting_id = de_setting.id

        @gene_list.title = params[:title]
        @gene_list.description = params[:description]
        @gene_list.id_type = params[:id_type]
        @gene_list.columns = params[:columns]
        @gene_list.rows = params[:rows]
        @gene_list.save!
        render json: {msg: "Saved", id: @gene_list.id}
    end

    def destroy
        de_setting = DeSetting.find_by_secure_id(params[:id])
        gene_list = GeneList.find_by_id(params[:gene_list_id])

        if !de_setting || !gene_list
            render json: {
                status: 403,
                message: "No such object"
              }.to_json
            return
        end

        p de_setting
        p gene_list

        if de_setting.can_modify(current_user) && gene_list.de_setting==de_setting
            gene_list.destroy
            render json: {
                status: 200,
                message: "Gene list deleted"
              }.to_json
            return
        else
            render json: {
                status: 403,
                message: "Access denied"
              }.to_json
            return
        end
    end

end
