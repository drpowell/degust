class BackendNone
    constructor: (@settings, @events) ->

    request_data: () ->
        @events.$emit("start_loading")
        if @settings.csv_data
            # csv data is already in document
            log_info("Using embedded csv")
            @_data_ready(@settings.csv_data)
        else
            d3.text(@settings.csv_file, "text/csv", (err,dat) =>
                log_info("Downloaded csv")
                log_debug("Downloaded csv",dat,err)
                if err
                    log_error(err)
                    return
                @_data_ready(dat)
            )

    _data_ready: (dat) ->
        if @settings.csv_format
            data = d3.csv.parse(dat)
        else
            data = d3.tsv.parse(dat)
        @events.$emit("dge_data", data, @settings.columns)
        @events.$emit("done_loading")

    request_kegg_data: (callback) ->
        log_error("Get KEGG data not supported without backend")

# BackendCommon - used by both WithBackendNoAnalysis and WithBackendAnalysis
class BackendCommon
    @script: (code,typ,params) ->
        "#{code}/#{typ}" + if params then "?#{params}" else ""

    constructor: (@settings) ->
        # Pass

    request_kegg_data: (callback) ->
        d3.tsv(BackendCommon.script(this.code, 'kegg_titles'), (err,ec_data) ->
            log_info("Downloaded kegg : rows=#{ec_data.length}")
            log_debug("Downloaded kegg : rows=#{ec_data.length}",ec_data,err)
            callback(ec_data)
        )

class BackendPreAnalysed
    constructor: (@code, @settings, @events) ->
        @common = new BackendCommon(@settings)

    is_configured: () ->
        @settings.fc_columns.length > 0

    request_kegg_data: (callback) ->
        @common.request_kegg_data(callback)

    request_data: () ->
        new Promise((resolve) =>
            req = BackendCommon.script(this.code, "csv")
            @events.$emit("start_loading")
            d3.text(req, (err, dat) =>
                log_info("Downloaded DGE CSV: len=#{dat.length}")
                @events.$emit("done_loading")
                if err
                    log_error(err)
                    return

                if @settings.csv_format
                    data = d3.csv.parse(dat)
                else
                    data = d3.tsv.parse(dat)
                log_info("Parsed DGE CSV : rows=#{data.length}")
                log_debug("Parsed DGE CSV : rows=#{data.length}",data,err)

                data_cols = @settings.info_columns.map((n) -> {idx: n, name: n, type: 'info' })
                data_cols.push({idx: '_dummy', type: 'primary', name:@settings.primary_name})
                @settings.fc_columns.forEach((n) ->
                    data_cols.push({idx: n, type: 'fc', name: n})
                )
                data_cols.push({idx: @settings.fdr_column, name: @settings.fdr_column, type: 'fdr'})
                data_cols.push({idx: @settings.avg_column, name: @settings.avg_column, type: 'avg'})
                if @settings.ec_column?
                    data_cols.push({idx: @settings.ec_column, name: 'EC', type: 'ec'})
                if @settings.link_column?
                    data_cols.push({idx: @settings.link_column, name: 'link', type: 'link'})

                resolve([data, data_cols])
            )
        )


    dge_methods: () ->
        []

    qc_plots: () ->
        []

    request_r_code: () ->
        "This data is pre-analysed. No R code available."

class BackendRNACounts
    constructor: (@code, @settings, @events) ->
        @common = new BackendCommon(@settings)

    dge_methods: () ->
        res = []
        if @have_replicates()
            res.push(
                ['voom', 'Voom/Limma'],
                ['edgeR-quasi', 'edgeR quasi-likelihood'],
                ['edgeR', 'edgeR'],
                ['voom-weights', 'Voom (samp weights)']
            )
        res.push(['logFC-only', 'LogFC only (no P-values)'])
        res

    # Do we have more than 1 replicate in *any* of our conditions
    have_replicates: () ->
        @settings.replicates.map(([name,reps]) -> reps.length).some((x) -> x>1)

    #Consider refactoring dge_methods to be an array of objects instead of array of arrays to match,
    #Or just change this to match dge_methods
    #May want to have single combined list of dge_methods and qc plots
    qc_plots: () ->
        [
            ['pvalue',             'p-Value Histogram'],
            ['library-size',       'Library Size'],
            ['expression-boxplot', 'Expression Boxplot'],
            ['rle-boxplot',        'RLE Boxplot']
        ]

    is_configured: () ->
        @settings.replicates.length > 0

    request_kegg_data: (callback) ->
        @common.request_kegg_data(callback)

    request_data: (method,columns,contrasts) ->
        @_request_dge_data(method,columns,contrasts)

    _request_from_params: (call, params) ->
        arr = []
        for k,v of params
            if typeof v == 'string'
                arr.push("#{k}=#{v}")
            else
                arr.push("#{k}=#{encodeURIComponent(JSON.stringify v)}")

        BackendCommon.script(this.code, call, arr.join("&"))

    _gen_request: (call, method, columns, contrast, opt) ->
        if contrast
            hsh = {method: method, contrast: contrast}
        else
            hsh = {method: method, fields: columns}
        Object.assign(hsh, opt)
        @_request_from_params(call, hsh)

    _request_dge_data: (method,columns,contrast) ->
        console.log "request_dge_data",method,columns,contrast
        return if columns.length <= 1 && !contrast

        # load csv file and create the chart
        req = @_gen_request('dge', method, columns, contrast)
        @events.$emit("start_loading")
        new Promise((resolve) =>
            d3.json(req, (err, json) =>
                @events.$emit("done_loading")

                if err
                    log_error(err)
                    return

                if (json.error?)
                    @events.$emit("errorMsg", json.error)
                    log_error("Error doing DGE",json.error)
                    return

                data = d3.csv.parse(json.csv);
                log_info("Downloaded DGE counts : rows=#{data.length}")
                log_debug("Downloaded DGE counts : rows=#{data.length}",data,err)
                log_info("Extra info : ",json.extra)


                data_cols = @settings.info_columns.map((n) -> {idx: n, name: n, type: 'info' })
                pri=true
                columns.forEach((n) ->
                    typ = if pri then 'primary' else 'fc'
                    data_cols.push({idx: n, type: typ, name: n})
                    pri=false
                )
                if contrast
                    data_cols.push({idx: "primary", type:'primary', name: "primary"})
                    data_cols.push({idx: contrast.name, type:'fc', name: contrast.name})

                data_cols.push({idx: 'adj.P.Val', name: 'FDR', type: 'fdr'})
                data_cols.push({idx: 'AveExpr', name: 'AveExpr', type: 'avg'})
                if data[0]["P.Value"]?
                    data_cols.push({idx: 'P.Value', name: 'P value', type: 'p'})

                if @settings.ec_column?
                    data_cols.push({idx: @settings.ec_column, name: 'EC', type: 'ec'})
                if @settings.link_column?
                    data_cols.push({idx: @settings.link_column, name: 'link', type: 'link'})
                @settings.replicates.forEach(([name,reps]) ->
                    reps.forEach((rep) ->
                        data_cols.push({idx: rep, name: rep, type: 'count', parent: name})
                    )
                )

                resolve([data, data_cols, json.extra])
            )
        )

    request_r_code: (method,columns,contrast) ->
        new Promise((resolve) =>
            req = @_gen_request('dge_r_code', method, columns,contrast)
            d3.text(req, (err,data) ->
                log_debug("Downloaded R Code : len=#{data.length}",data,err)
                resolve(data)
            )
        )

    request_normalized: (normalized, method,columns,contrast) ->
        new Promise((resolve) =>
            req = @_gen_request('dge', method, columns,contrast,{normalized: normalized})
            d3.json(req, (err,data) ->
                log_debug("Downloaded R Code : len=#{data.length}",data,err)
                resolve(data)
            )
        )

class BackendMaxQuant
    constructor: (@code, @settings, @events) ->
        @common = new BackendCommon(@settings)

    is_configured: () ->
        @settings.replicates.length > 0

    dge_methods: () ->
        [ ['maxquant', 'MaxQuant with Limma']
        ]

    qc_plots: () ->
        [
            ['pvalue',                'p-value Histogram'],
            ['expression-boxplot',    'Intensity Boxplot'],
            ['cv-plot',               'CV-Hisogram'],
            ['quant-plot',            'Quantified Histogram']
            ['intensity-plot',        'Intensity Histogram']
            ['imputed-heatmap',       'Imputed Value Heatmap']
        ]

    request_kegg_data: (callback) ->
        console.log "not supported"

    request_data: (method,columns) ->
        @_request_dge_data(method,columns)

    _request_from_params: (call, params) ->
        arr = []
        for k,v of params
            if typeof v == 'string'
                arr.push("#{k}=#{v}")
            else
                arr.push("#{k}=#{encodeURIComponent(JSON.stringify v)}")

        BackendCommon.script(this.code, call, arr.join("&"))

    _gen_request: (call, method, columns, contrast, opt) ->
        if contrast
            hsh = {method: method, contrast: contrast}
        else
            hsh = {method: method, fields: columns}
        Object.assign(hsh, opt)
        @_request_from_params(call, hsh)

    _request_dge_data: (method,columns) ->
        console.log "request_dge_data",method,columns
        return if columns.length <= 1

        # load csv file and create the chart
        req = BackendCommon.script(this.code, "dge","method=maxquant&fields=#{encodeURIComponent(JSON.stringify columns)}")
        @events.$emit("start_loading")
        new Promise((resolve) =>
            d3.json(req, (err, json) =>
                @events.$emit("done_loading")

                if err
                    log_error(err)
                    return

                if (json.error?)
                    @events.$emit("errorMsg", json.error)
                    log_error("Error doing DGE",json.error)
                    return

                data = d3.csv.parse(json.csv);
                log_info("Downloaded DGE counts : rows=#{data.length}")
                log_debug("Downloaded DGE counts : rows=#{data.length}",data,err)
                log_info("Extra info : ",json.extra)


                data_cols = @settings.info_columns.map((n) -> {idx: n, name: n, type: 'info' })
                pri=true
                columns.forEach((n) ->
                    typ = if pri then 'primary' else 'fc'
                    data_cols.push({idx: n, type: typ, name: n})
                    pri=false
                )
                data_cols.push({idx: 'adj.P.Val', name: 'FDR', type: 'fdr'})
                data_cols.push({idx: 'AveExpr', name: 'AveExpr', type: 'avg'})
                if data[0]["P.Value"]?
                    data_cols.push({idx: 'P.Value', name: 'P value', type: 'p'})

                if @settings.ec_column?
                    data_cols.push({idx: @settings.ec_column, name: 'EC', type: 'ec'})
                if @settings.link_column?
                    data_cols.push({idx: @settings.link_column, name: 'link', type: 'link'})
                @settings.replicates.forEach(([name,reps]) ->
                    reps.forEach((rep) ->
                        data_cols.push({idx: rep, name: rep, type: 'count', parent: name})
                    )
                )
                @settings.replicates.forEach(([name,reps]) ->
                    reps.forEach((rep) ->
                        data_cols.push({idx: rep + " imputed", name: rep + " imputed", type: 'imputed', parent: name})
                    )
                )

                resolve([data, data_cols])
            )
        )

    request_r_code: (method,columns) ->
        new Promise((resolve) =>
            req = BackendCommon.script(this.code, "dge_r_code","method=#{method}&fields=#{encodeURIComponent(JSON.stringify columns)}")
            d3.text(req, (err,data) ->
                log_debug("Downloaded R Code : len=#{data.length}",data,err)
                resolve(data)
            )
        )

    request_normalized: (normalized, method,columns,contrast) ->
        new Promise((resolve) =>
            req = @_gen_request('dge', method, columns,contrast,{normalized: normalized})
            d3.json(req, (err,data) ->
                log_debug("Downloaded R Code : len=#{data.length}",data,err)
                resolve(data)
            )
        )


module.exports =
    BackendNone: BackendNone
    BackendCommon: BackendCommon
    BackendRNACounts: BackendRNACounts
    BackendPreAnalysed: BackendPreAnalysed
    BackendMaxQuant: BackendMaxQuant
