class DegustController < ApplicationController
    # Skip CSRF for static pages (these are safe anyway)
    # FIXME: Also skip CSRF for saving settings.  The frontend should send the tokens.  Careful to still allow CLI where appropriate
    skip_before_action :verify_authenticity_token, :only => [:static, :save_settings]

    def static
        version = params['version'] || ''
        filename = dir_for_version(version) + "/#{params['page'].to_s}.#{params['format'].to_s}"

        if filename.include?('..') || !File.exists?(filename)
            raise ActionController::RoutingError.new('Not Found')
        else
            send_file filename, disposition: 'inline'
        end
    end

    def static_kegg
        page = 'degust-frontend/kegg/' + params['page'].to_s + '.' + params['format'].to_s
        if page.include?('..') || !File.exists?(page)
            raise ActionController::RoutingError.new('Not Found')
        else
            send_file page, disposition: 'inline'
        end
    end

    def partial_csv
        de_setting = DeSetting.find_by_secure_id(params[:id])
        res = IO.binread(de_setting.user_file.location, 10240)
        send_data res
    end

    def csv
        de_setting = DeSetting.find_by_secure_id(params[:id])
        send_file de_setting.user_file.location, :filename => ""  # Don't suggest a filename
    end

    def settings
        de_setting = DeSetting.find_by_secure_id(params[:id])
        if de_setting.nil?
            raise ActionController::RoutingError.new('Not Found')
        end

        # Store this visit in "visited"
        if !current_user.nil?
            v = de_setting.visiteds.find_or_create_by(:user => current_user)
            v.last = DateTime.now
            v.save
        end
        res = {settings: de_setting.settings_with_defaults}
        res['degust_name'] = helpers.app_name
        res['extra_menu_html'] = render_to_string(partial: 'layouts/navigation_links.html.erb')
        res['is_logged_in'] = !current_user.nil?
        res['is_owner'] = de_setting.is_owner(current_user)
        if de_setting.is_owner(current_user)
            res['delete_url'] = de_setting_path(params[:id])
            res['tok'] = form_authenticity_token
        end
        render :json => res
    end

    def save_settings
        de_setting = DeSetting.find_by_secure_id(params[:id])
        new_settings = JSON.parse(params['settings'])

        if !de_setting.can_modify(current_user)
            render status: 400, plain: 'Access denied : locked'
            return
        end

        # Not allowed to set "locked" unless you own it
        if !de_setting.is_owner(current_user) && new_settings['config_locked']
            render status: 400, plain: 'Access denied : not-owner'
            return
        end

        ok = de_setting.update_from_json(new_settings)
        if !ok
            #raise ActionController::BadRequest.new('Invalid character in field')
            render status: 400, plain: 'Invalid character in field'
        else
            de_setting.save!
        end
    end

    def dge
        de_setting = DeSetting.find_by_secure_id(params[:id])

        cacheKey = [de_setting.settings_with_defaults, params].to_s
        cache = ActiveSupport::Cache::FileStore.new("#{Rails.root.to_s}/tmp/R-cache", expires_in: 7.days)
        fromCache=true
        json = cache.fetch(cacheKey) do
                  logger.info "Not cached."
                  fromCache=false
                  make_code = lambda {|tempfile| DegustLogic.get_r_code(de_setting, params, tempfile)}
                  DegustLogic.run_r_code(make_code)
               end
        # Don't cache output with error
        if json.key?(:error)
            cache.delete(cacheKey)
        end
        (json[:extra]||={})[:fromCache] = fromCache
        render json: json
    end

    def dge_r_code
        de_setting = DeSetting.find_by_secure_id(params[:id])
        str = DegustLogic.get_r_code(de_setting, params, 'output_dir', false)
        json = DegustLogic.run_r_code( lambda{|tempfile| DegustLogic.get_versions_code()} )
        render plain: str + json[:stdout].html_safe
    end

    require 'csv'
    def kegg_titles
        de_setting = DeSetting.find_by_secure_id(params[:id])
        lst = CSV.read("degust-frontend/kegg/pathway/map_title.tab", { :col_sep => "\t" })

        buf = [%w(code title ec)]
        lst.each do |codeTitle|
            f = "degust-frontend/kegg/kgml/map/map"+codeTitle[0]+".xml"
            ecs=[]
            if File.exists?(f)
                data = File.read(f)
                ecs = data.scan(/name="ec:([.\d]+)"/)
            end
             buf.push([codeTitle[0], codeTitle[1], ecs.join(' ')])
        end
        #send_data buf.to_csv(:col_sep => "\t", :row_sep => "\n")
        send_data buf.map {|x| x.join("\t")}.join("\n") + "\n"
    end

end
