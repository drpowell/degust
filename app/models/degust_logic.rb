require 'open3'

class DegustLogic

    def self.get_r_code(de_setting, query, output_dir, real=true)
        fields = JSON.parse(query['fields'])
        settings = de_setting.settings_with_defaults
        params = {
                "sep_char" => settings['csv_format'] ? "," : "\t",
                "counts_file" => real ? de_setting.user_file.location : de_setting.user_file.name,
                "counts_skip" => 0,
                "columns" => arrToR(count_columns(settings), true),
                "min_counts" => force_num(settings['min_counts']),
                "min_cpm" => force_num(settings['min_cpm']),
                "min_cpm_samples" => force_num(settings['min_cpm_samples']),
                "design" => matToR(design_matrix(settings)),
                "cont_matrix" => matToR(cont_matrix(settings, fields)),
                "export_cols" => arrToR(export_cols(settings), true),
                "output_dir" => output_dir,
            }
        method = case query['method']
                 when 'voom' then 'voom'
                 when 'edgeR' then 'edgeR'
                 when 'edgeR-quasi' then 'edgeR-quasi'
                 when 'voom-weights' then 'voom-weights'
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

        sout = serr = exit_status = nil
        Open3.popen3('R','-q','--vanilla') do |stdin, stdout, stderr, wait_thr|
            stdin.write(code)
            stdin.close_write
            exit_status = wait_thr.value
            sout = stdout.read
            serr = stderr.read
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
        FileUtils.remove_dir(tempfile)

        return res
    end

private
    def self.force_num(str)
        str.to_f
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
        pri = conds.shift
        conds.each do |cond|
            col = []
            col = settings['replicates'].map {|c| c[0]==pri ? -1 : c[0]==cond ? 1 : 0}
            mat.push(col)
            col_names.push(cond)
        end
        replicate_names = settings['replicates'].map {|r| r[0]}
        return {'mat'=>mat, 'col_names'=>col_names, 'row_names' => replicate_names}
    end
end
