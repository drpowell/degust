class DegustController < ApplicationController
    skip_before_action :verify_authenticity_token, :only => [:static, :save_settings]

    def static
        page = 'degust-frontend/degust-dist/' + params['page'].to_s + '.' + params['format'].to_s
        if page.include?('..') || !File.exists?(page)
            raise ActionController::RoutingError.new('Not Found')
        else
            send_file page, disposition: 'inline'
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
        send_file de_setting.user_files.location
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
        res = de_setting.settings_with_defaults
        res['extra_menu_html'] = render_to_string(partial: 'layouts/navigation_links.html.erb')
        render :json => res
    end

    def save_settings
        de_setting = DeSetting.find_by_secure_id(params[:id])
        ok = de_setting.update_from_json(JSON.parse(params['settings']))
        if !ok
            #raise ActionController::BadRequest.new('Invalid character in field')
            render status: 400, text: 'Invalid character in field'
        else
            de_setting.save!
        end
    end

    def dge
        de_setting = DeSetting.find_by_secure_id(params[:id])

        cacheKey = [de_setting.settings_with_defaults, params].to_s
        cache = ActiveSupport::Cache::FileStore.new("#{Rails.root.to_s}/tmp/R-cache", expires_in: 7.days)
        json = cache.fetch(cacheKey) do
                  logger.info "Not cached."
                  DegustLogic.run_r_code(de_setting, params)
               end
        render json: json
    end

    def dge_r_code
        de_setting = DeSetting.find_by_secure_id(params[:id])
        str = DegustLogic.get_r_code(de_setting, params, 'output_dir', false)
        render plain: str
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
#
#     var readOne = function(lst, buf) {
#         var codeTitle = lst.shift();
#         if (!codeTitle || codeTitle.length<2) {
#             var str = buf.map(function(l) {return l.join("\t");}).join("\n") + "\n";
#             res.setHeader('content-type', 'text/csv');
#             return res.send(str);
#         }
#         fs.readFile(__dirname + "/kegg/kgml/map/map"+codeTitle[0]+".xml", function(err, data) {
#             var ecs = [];
#             if (!err) {
#                 var re = /name="ec:([.\d]+)"/g;
#                 var m;
#                 do {
#                     m = re.exec(data);
#                     if (m) {
#                         ecs.push(m[1]);
#                     }
#                 } while (m);
#             }
#             buf.push([codeTitle[0], codeTitle[1], ecs.join(" ")]);
#             readOne(lst, buf);
#         });
#     };
#     readOne(lst, [["code","title","ec"]]);
# });

end
