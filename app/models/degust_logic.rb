require 'open3'
require 'timeout'

class DegustLogic

    def self.get_r_code(de_setting, query, output_dir, real=true)
        settings = de_setting.settings_with_defaults

        if query['fields']
            fields = JSON.parse(query['fields'])
            cont_mat = cont_matrix(settings, fields)
        elsif query['contrast']
            contrast = JSON.parse(query['contrast'])
            cont_mat = explicit_cont_matrix(settings, contrast["name"], contrast["column"])
        else
            raise "Bad query"
        end

        # Return normalized data, or batch effect removed?
        normalized = case query['normalized']
                     when 'backend' then 'backend'
                     when 'remove-hidden' then 'remove-hidden'
                     else ''
                     end
        params = {
                "sep_char" => settings['csv_format'] ? "," : "\t",
                "counts_file" => real ? de_setting.user_file.location : de_setting.user_file.name,
                "columns" => arrToR(count_columns(settings), true),
                "min_counts" => force_num(settings['min_counts']),
                "min_cpm" => force_num(settings['min_cpm']),
                "min_cpm_samples" => force_int(settings['min_cpm_samples']),
                "design" => matToR(design_matrix(settings)),
                "cont_matrix" => matToR(cont_mat),
                "normalized" => normalized,
                "hidden_factors" => arrToR(settings["hidden_factor"] || [], true),
                "export_cols" => arrToR(export_cols(settings), true),
                "output_dir" => output_dir,
                "skip_header_lines" => force_int(settings['skip_header_lines']),
                "model_only_selected" => boolToR(settings['model_only_selected']),
                "filter_rows" => (settings["filter_rows"] || []).to_json,
            }
        method = case query['method']
                 when 'voom' then 'voom'
                 when 'edgeR' then 'edgeR'
                 when 'edgeR-quasi' then 'edgeR-quasi'
                 when 'voom-weights' then 'voom-weights'
                 when 'maxquant' then 'maxquant'
                 when 'logFC-only' then 'logFC-only'
                 end

        return nil if method.nil?

        ApplicationController.render(template: "degust/#{method}.R.erb", assigns: params, layout: false)
    end

    def self.get_versions_code()
        ApplicationController.render(template: "degust/versions.R.erb", layout: false)
    end

    def self.run_r_code(make_code)
        tempfile = Dir.mktmpdir("R-tmp", "#{Rails.root.to_s}/tmp/")
        code = make_code.call(tempfile)

        sout = serr = exit_status = timeout = nil
        Open3.popen3('R','-q','--vanilla') do |stdin, stdout, stderr, wait_thr|
            begin
                Timeout.timeout(120) do   # R has to complete running within this time
                    stdin.write(code)
                    stdin.close_write
                    exit_status = wait_thr.value
                    sout = stdout.read
                    serr = stderr.read
                end
            rescue Timeout::Error => e
                STDERR.puts "Timeout ruby run : #{e.inspect}"
                timeout = true
                Process.kill("KILL", wait_thr.pid)
            end
        end
        if (timeout)
            return {error: {input: code, msg: "R run timed out", stdout: sout, exit_status: exit_status}}
        end
        if (exit_status.exitstatus != 0)
            return {error: {input: code, msg: serr, stdout: sout, exit_status: exit_status}}
        end

        output = ""
        begin
            output = File.read(tempfile + '/output.txt')
        rescue Errno::ENOENT
            # Ignore
        end

        extra = ""
        begin
            extra = JSON.parse(File.read(tempfile +"/extra.json"))
        rescue Errno::ENOENT
            # Ignore
        end

        res = {csv: output, extra: extra, stdout: sout, stderr: serr }
        return res
    ensure
        FileUtils.remove_dir(tempfile)
    end

private
    def self.force_num(str)
        str.to_f
    end

    def self.force_int(str)
        str.to_i
    end

    def self.boolToR(bool)
        if (bool)
            "TRUE"
        else
            "FALSE"
        end
    end

    def self.count_columns(settings)
        cols = {}
        settings['replicates'].each {|arr| arr[1].each {|c| cols[c]=1 } }
        cols.keys.sort
    end

    def self.arrToR(arr, quot=false)
        "c(" + arr.map {|x| if (quot) then "'"+x+"'" else x end}.join(",") + ")"
    end

    def self.matToR(arr, quot=false)
        "matrix("+arrToR(arr['mat'].map {|x| arrToR(x,quot)} ) +
               ", ncol=#{arr['mat'].length}" +
               ", dimnames=list("+arrToR(arr['row_names'],true)+","+arrToR(arr['col_names'],true)+"))"
    end

    def self.export_cols(settings)
        arr = settings['info_columns']
        settings['replicates'].each do |r|
            arr = arr.concat(r[1])
        end
        if (settings['ec_column'])
            arr.push(settings['ec_column'])
        end
        return arr
    end

    # Create design matrix.  Columns are in order of "replicates" array.   Rows in order as done by count_columns()
    def self.design_matrix(settings)
        mat = []
        count_cols = count_columns(settings)
        col_names = []
        settings['replicates'].each do |arr|
            col = count_cols.map {|c| arr[1].include?(c) ? 1 : 0}
            mat.push(col)
            col_names.push(arr[0])
        end
        return {'mat' => mat, 'col_names' => col_names, 'row_names' => count_cols}
    end

    # Create contrast matrix.  Columns are in order of passed "conditions" array.
    # Rows in order of columns from design_matrix()
    def self.cont_matrix(settings, conds)
        mat = []
        col_names = []
        pri = conds[0]
        conds.drop(1).each do |cond|
            if DeSetting::BAD_REGEX.match?(cond)
                raise "Invalid character in condition"
            end

            col = []
            col = settings['replicates'].map {|c| c[0]==pri ? -1 : c[0]==cond ? 1 : 0}
            mat.push(col)
            col_names.push(cond)
        end
        replicate_names = settings['replicates'].map {|r| r[0]}
        return {'mat'=>mat, 'col_names'=>col_names, 'row_names' => replicate_names}
    end

    # Alterative to "cont_matrix" above, but with explicit contrast
    def self.explicit_cont_matrix(settings, name, column)
        if DeSetting::BAD_REGEX.match?(name)
            raise "Invalid character in name"
        end
        if column.any? {|x| DeSetting::BAD_REGEX.match?(x.to_s)}
            raise "Invalid character in name"
        end
        mat = [column]
        replicate_names = settings['replicates'].map {|r| r[0]}
        return {'mat'=>mat, 'col_names'=>[name], 'row_names' => replicate_names}
    end
end
