
blue_to_brown = d3.scale.linear()
  .domain([0,0.05,1])
  .range(['brown', "steelblue", "steelblue"])
  .interpolate(d3.interpolateLab)

about = require('./about.vue').default
navbar = require('./navbar.vue').default

backends = require('./backend.coffee')
sliderText = require('./slider.vue').default
conditions = require('./conditions-selector.vue').default
filterGenes = require('./filter-genes.vue').default
extraInfo = require('./extra-info.vue').default
modalExpDesc = require('./modal-ExpDesc.vue').default
ErrorMsg = require('./modal-error-msg.vue').default
geneTable = require('./gene-table.vue').default
maPlot = require('./ma-plot.vue').default
volcanoPlot = require('./volcano-plot.vue').default
mdsPlot = require('./mds-plot.vue').default
topconfect = require('./topconfect.vue').default
qcPlots = require('./qc-plots.vue').default
geneStripchart = require('./gene-stripchart.vue').default
parallelCoord = require('./parcoords.vue').default
heatmap = require('./heatmap.vue').default
{ Normalize } = require('./normalize.coffee')
{ GeneData } = require('./gene_data.coffee')

module.exports =
    name: 'compare-single'
    props:
        inputSettings:
            default: () -> {}
        inputCode: null
        navbar:
            default: () -> true
        shown:
            default: true              # Can be useful to allow this to trigger redraws, etc

    components:
        about: about
        navbar: navbar

        sliderText: sliderText
        conditionsSelector: conditions
        filterGenes: filterGenes
        extraInfo: extraInfo
        ErrorMsg: ErrorMsg
        modalExpDesc: modalExpDesc
        geneTable: geneTable
        maPlot: maPlot
        volcanoPlot: volcanoPlot
        mdsPlot: mdsPlot
        topconfect: topconfect
        qcPlots: qcPlots
        geneStripchart: geneStripchart
        parallelCoord: parallelCoord
        heatmap: heatmap
    data: () ->
        code: null
        settings: {}
        full_settings:
            extra_menu_html: ''
        load_failed: false
        load_success: false
        num_loading: 0
        fdrThreshold: 1
        fcThreshold: 0
        confectThreshold: 0
        fc_relative_i: null
        ma_plot_fc_col_i: null
        fcStepValues:
            Number(x.toFixed(2)) for x in [0..5] by 0.01
        numGenesThreshold: 100
        skipGenesThreshold: 0
        mdsDimension: 1
        normalization: 'cpm'
        normalizationModeration: 10
        normalizationColumns: null
        normalized_data: null
        maxGenes: 0
        mds_2d3d: '2d'
        mdsDimensionScale: 'independent'
        r_code: ''
        dge_parameters:
            confect_fdr: 0.05
            ruv:
                flavour: 'ruvg'
                k: 1
                prop_empirical: 0.5
                normalization: 'TMM'
        dge_method: null
        dge_methods: []
        qc_plots: []
        showGeneList: false
        filter_gene_list: []
        sel_conditions: []             # Array of condition names currently selected to compare
        sel_contrast: null             # Contrast if selected.  Hash with name, and columns
        cur_plot: null
        cur_opts: 'options'
        gene_data: new GeneData([],[])
        genes_selected: []              # Selected by "brushing" on one of the plots
        genes_highlight: []             # Gene hover from 'mouseover' of table
        genes_hover: []                 # Genes hover from 'mouseover' of plot
        show_heatmap: true
        heatmap_show_replicates: false
        show_qc: ''
        show_about: false
        show_extraInfo: false
        extraInfo_data: null
        error_msg: null
        show_Error: false
        show_hoverDesc: false
        show_ModalExperimentDesc: false
        descTooltipLoc: [0,0]
        confect_data_present: false
        #colour_by_condition: null  # Don't want to track changes to this!

    computed:
        home_link: () -> this.settings?.home_link || '/'
        fdrWarning: () -> this.cur_plot == 'mds' && this.fdrThreshold<1
        fcWarning: () -> this.cur_plot == 'mds' && (this.fcThreshold>0 || this.confectThreshold>0)
        minCpmWarning: () ->
            if (!Object.keys(this.settings).length)
                return false
            !(this.settings?.min_counts>0) &&
                !(this.settings?.min_cpm>0 && this.settings?.min_cpm_samples)

        experimentName: () -> this.settings?.name || "Unnamed"
        can_configure: () ->
            !this.settings.config_locked || this.full_settings.is_owner
        config_url: () -> "config.html?code=#{this.code}"
        gene_data_rows: () ->
            this.gene_data.get_data()
        expr_data: () ->
            console.log "computing expr_data.  orig length=", this.gene_data.get_data().length
            Vue.noTrack(this.gene_data.get_data().filter((v) => this.expr_filter(v)))
        avg_column: () ->
            this.gene_data.columns_by_type('avg')[0]
        fdr_column: () ->
            this.gene_data.columns_by_type('fdr')[0]
        fc_relative: () ->
            if this.fc_relative_i>=0
                this.fc_columns[this.fc_relative_i]
            else
                'avg'
        ma_plot_fc_col: () ->
            this.fc_calc_columns[this.ma_plot_fc_col_i]
        fc_columns: () ->
            this.gene_data.columns_by_type(['fc','primary'])
        fc_calc_columns: () ->
            this.fc_relative     # Listed so to create a dependency.
            this.gene_data.columns_by_type(['fc_calc'])
        info_columns: () ->
            this.gene_data.columns_by_type(['info'])
        count_columns: () ->
            if this.extraInfo_data? && this.extraInfo_data.conditions_used?
                fc_names = this.extraInfo_data.conditions_used
            else
                # Otherwise, try from the FC column names
                fc_names = this.fc_calc_columns.map((c) -> c.name)
            this.gene_data.columns_by_type('count').filter((c) -> fc_names.indexOf(c.parent)>=0)

        filter_changed: () ->
            this.fdrThreshold
            this.fcThreshold
            this.confectThreshold
            this.filter_gene_list_cache
            Date.now()
        need_renormalization: () ->
            this.normalization
            this.normalizationModeration
            Date.now()
        heatmap_dimensions: () ->
            if (!this.heatmap_show_replicates)
                heatmap_dims = this.gene_data.columns_by_type('fc_calc_avg')
            else
                heatmap_dims = this.normalizationColumns
            heatmap_dims
        filter_gene_list_cache: () ->
            res = {}
            this.filter_gene_list.forEach((val) -> res[val] = val)
            res

        #Added to show/hide counts/intensity
        is_pre_analysed: () ->
            this.settings.input_type == 'preanalysed'
        is_rnaseq_counts: () ->
            this.settings.input_type == 'counts'
        is_maxquant: () ->
            this.settings.input_type == 'maxquant'

        tooltipStyleDesc: () ->
            {left: (this.descTooltipLoc[0])+'px', top: (this.descTooltipLoc[1] + window.pageYOffset)+'px'}
            # {left: (this.descTooltipLoc[0])+'px', top: undefined}

        avail_normalization: () ->
            res = [{key:'cpm', name:'CPM'},
                   {key:'backend', name:'Backend normalization'}
                  ]
            if (this.settings.hidden_factor && this.settings.hidden_factor.length>0)
                res.push({key:'remove-hidden', name:'Subtract hidden factors'})
            res

    watch:
        '$route': (n,o) ->
            this.parse_url_params(n.query)
        settings: () ->
            this.dge_method = this.settings.dge_method || ''
            this.sel_conditions = this.$route.query.sel_conditions || this.settings.init_select || []
            this.$global.asset_base = this.settings?.asset_base || ''

        cur_plot: () ->
            # On plot change, reset brushes
            this.genes_highlight = []
            this.genes_selected = this.gene_data.get_data()
            this.checkPlotWarning()
        maxGenes: (val) ->
            this.$refs.num_genes.set_max(this.numGenesThreshold, 1, val, true)
            this.$refs.skip_genes.set_max(this.skipGenesThreshold, 0, val, true)
        fc_relative: () ->
            this.gene_data.set_relative(this.fc_relative)
        experimentName: () ->
            document.title = this.experimentName
        need_renormalization: () ->
            this.renormalize()
        shown: () ->
            this.$emit('resize')
        fdrWarning: () ->
            this.warningToggle(this.fdrWarning, 'fdrWarningElem', "MDS misleading : using FDR filter")
        fcWarning: () ->
            this.warningToggle(this.fcWarning, 'fcWarningElem', "MDS misleading : using FC filter")
        minCpmWarning: () ->
            this.warningToggle(this.minCpmWarning, 'minCpmElem', 'No gene expression filter.<br/>We recommend setting "<b>Min&nbsp;gene&nbsp;CPM</b>" in Configure')

    methods:
        init: () ->
            if !this.inputCode? && Object.keys(this.inputSettings).length==0
                log_error("No code, or settings specified")
            else if Object.keys(this.inputSettings).length>0
                # This is used when data is embedded in the html page
                this.load_success=true
                this.settings = this.inputSettings
                this.$nextTick(() -> this.initBackend(false))
            else
                this.code = this.inputCode
                log_info("Loading settings for code : #{this.code}")
                $.ajax({
                    type: "GET",
                    url: backends.BackendCommon.script(this.code,"settings"),
                    dataType: 'json'
                }).done((json) =>
                    this.full_settings = json
                    this.settings = json.settings

                    # Deal with old "analyze_server_side" option
                    if this.settings.analyze_server_side? && !this.settings.input_type?
                        this.settings.input_type = if this.settings.analyze_server_side then 'counts' else 'preanalysed'

                    this.load_success=true
                    this.$nextTick(() -> this.initBackend(true))
                 ).fail((x) =>
                    log_error "Failed to get settings!",x
                    this.load_failed = true
                    this.$nextTick(() ->
                        if (this.error_msg)
                            this.error_msg.msg = x.responseText
                        this.show_Error = true
                    )
                )

        initBackend: (use_backend) ->
            this.ev_backend = new Vue()
            this.ev_backend.$on("start_loading", () => this.num_loading+=1)
            this.ev_backend.$on("done_loading", () => this.num_loading-=1)
            this.ev_backend.$on("errorMsg", (errorMsg) =>
                this.error_msg = errorMsg
                this.show_Error = true
                )
            if !use_backend
                this.backend = new backends.BackendNone(this.settings, this.ev_backend)
            else
                switch this.settings.input_type
                    when 'counts'
                        this.backend = new backends.BackendRNACounts(this.code, this.settings, this.ev_backend)
                    when 'maxquant'
                        this.backend = new backends.BackendMaxQuant(this.code, this.settings, this.ev_backend)
                    when 'preanalysed'
                        this.backend = new backends.BackendPreAnalysed(this.code, this.settings, this.ev_backend)
                    else
                        log_error("Unknown input_type : ",this.settings.input_type)

                # If we're not configured, redirect to the config page
                if !this.backend.is_configured()
                    window.location = this.config_url
                this.dge_methods = this.backend.dge_methods()
                this.qc_plots = this.backend.qc_plots()

                # If there is no default dge_method set, then use first thing in the list
                if this.dge_methods.length>0 && !this.settings.dge_method?
                    this.dge_method = this.dge_methods[0][0]

            this.request_data()

        # Send a request to the backend.  First request, or when selected samples has changed
        request_data: () ->
            p = this.backend.request_data(this.dge_method, this.sel_conditions, this.sel_contrast, this.dge_parameters)
            p.then(([data,cols,extra]) =>
                this.process_dge_data(Vue.noTrack(data),cols,extra)
            )

        process_dge_data: (data, cols, extra) ->
            this.gene_data = new GeneData(data, cols)
            if this.settings.nice_names?
                this.gene_data.set_column_renaming(this.settings.nice_names)
            if extra.normalized?
                Normalize.store_normalized(this.gene_data, this.count_columns, 'backend', extra.normalized)
            this.maxGenes = this.gene_data.get_data().length
            this.$awn.info("Loaded #{this.maxGenes} genes", {durations : {info: 3000}})
            this.numGenesThreshold = this.maxGenes
            this.fc_relative_i = 0
            this.ma_plot_fc_col_i = 1
            this.extraInfo_data = extra
            this.set_genes_selected(this.gene_data.get_data())
            this.genes_hover = [this.gene_data.get_data()[0]]
            this.genes_highlight = []
            this.colour_by_condition = if this.fc_columns.length<=10 then d3.scale.category10() else d3.scale.category20()
            if (!this.cur_plot? || this.cur_plot in ["parcoords","ma","topconfect"])
                if this.dge_method=='voom-topconfects'
                    this.cur_plot = 'topconfect'
                else
                    this.cur_plot = if this.fc_columns.length>2 then "parcoords" else "ma"
            if this.fc_columns.length==2
                this.heatmap_show_replicates = true
            this.confect_data_present = this.gene_data.column_by_type('confect')?
            this.confectThreshold = 0
            this.renormalize()
            this.checkPlotWarning()
            this.$emit('update', this.gene_data)

        # Returns a promise that will renormalize, and return the new columns
        get_normalized: (normalization, normalizationModeration) ->
            switch normalization
                when 'cpm'
                    new_cols = Normalize.normalize_cpm(this.gene_data, this.count_columns, normalizationModeration)
                    return new_cols
                when 'backend', 'remove-hidden'
                    this.ev_backend.$emit('start_loading')
                    p = this.backend.request_normalized(normalization, this.dge_method, this.sel_conditions, this.sel_contrast, this.dge_parameters)
                    new_cols = await Normalize.normalize_from_backend(this.gene_data, this.count_columns, normalization, p)
                    this.ev_backend.$emit('done_loading')
                    return new_cols

        renormalize: () ->
            this.get_normalized(this.normalization, this.normalizationModeration)
                .then((new_cols) => this.normalizationColumns = new_cols)

        # Selected samples have changed, request a new dge
        change_samples: (cur) ->
            this.dge_method = cur.dge_method
            this.sel_conditions = cur.sel_conditions
            this.sel_contrast = cur.sel_contrast
            this.dge_parameters = JSON.parse(JSON.stringify(cur.dge_parameters))  # Deep obj copy
            this.request_data()

        set_genes_selected: (d) ->
            this.genes_selected = Vue.noTrack(d)
        set_genes_highlight: (d) ->
            this.genes_highlight = Vue.noTrack(d)

        hover_heatmap: (d) ->
            this.genes_hover = this.genes_highlight = Vue.noTrack([d])
        stop_hover_heatmap: () ->
            this.genes_highlight=[]
        gene_table_hover: (d) ->
            this.genes_hover = this.genes_highlight = Vue.noTrack([d])
        gene_table_nohover: () ->
            this.genes_highlight=[]

        checkPlotWarning: () ->
            this.warningToggle(this.fc_calc_columns.length>2 && this.cur_plot=="ma",
                               'maPlotWarningElem', 'Using MA plot with >2 conditions')
            this.warningToggle(this.fc_calc_columns.length>2 && this.cur_plot=="volcano",
                               'volcanoPlotWarningElem', 'Using Volcano plot with >2 conditions')

        warningToggle: (warn, warnElem, msg) ->
            if warn && !this[warnElem]
                this[warnElem] = this.$awn.warning(msg)
            else if !warn && this[warnElem]
                this[warnElem].remove()
                this[warnElem] = null

        # Request and display r-code for current selection
        show_r_code: () ->
            p = this.backend.request_r_code(this.dge_method, this.sel_conditions, this.sel_contrast, this.dge_parameters)
            p.then((d) =>
                d = d.replace(/\t/g,'\\t')
                this.r_code = d
            )
        close_r_code: () -> this.r_code = ''

        plot_colouring: (d) ->
            blue_to_brown(d[this.fdr_column.idx])
        condition_colouring: (c) ->
            this.colour_by_condition(c)
        fmtPCAText: (v) ->
            v+" vs "+(v+1)
        fdrValidator: (v) ->
            n = Number(v)
            !(isNaN(n) || n<0 || n>1)
        intValidator: (v) ->
             n = Number(v)
             !(isNaN(n) || n<0)
        moderationValidator: (v) ->
            n = Number(v)
            !(isNaN(n) || n<=0)

        filterList: (value) ->
            this.filter_gene_list = value
            value

        # Check if the passed row passes filters for : FDR, FC, Kegg, Filter List
        expr_filter: (row)   ->
            #console.log "filter"
            if this.confectThreshold>0
                col = this.gene_data.column_by_type('confect')
                return false if Math.abs(row[col.idx]) < this.confectThreshold

            if this.fcThreshold>0
                # Filter using largest FC between any pair of samples
                fc = this.gene_data.columns_by_type('fc').map((c) -> row[c.idx])
                extent_fc = d3.extent(fc.concat([0]))
                if Math.abs(extent_fc[0] - extent_fc[1]) < this.fcThreshold
                    return false

            # Filter by genes in filter_gene_list
            if this.filter_gene_list.length > 0
                info_cols = this.gene_data.columns_by_type('info').map((c) -> row[c.idx])
                matching = info_cols.filter((col) =>
                    col.toLowerCase() of this.filter_gene_list_cache
                )
                if matching.length == 0
                    return false

            # Filter by FDR
            pval_col = this.fdr_column
            return false if row[pval_col.idx] > this.fdrThreshold

            true

        tip: (txt) ->
            {content:txt, placement:'left'}

        hoverExperimentDesc: () ->
            this.show_hoverDesc = true
            locRect = document.getElementById("experimentDescriptionLoc").getBoundingClientRect()
            this.descTooltipLoc = [(locRect.left + locRect.width + 1), locRect.top - 60] #Need to find a better way to set this y-axis location.
            return

        modalExperimentDesc: () ->
            this.show_ModalExperimentDesc = true
            return

        script: (typ) ->
            "#{this.code}/#{typ}"
        # This needs to have some/any feedback upon a(n) (un)successful save
        save: () ->
            # to_send = to_server_model(this.settings)
            $.ajax(
                type: "POST"
                url: this.script("settings")
                data: {settings: JSON.stringify(this.settings)}
                dataType: 'json'
            ).done((x) =>
            ).fail((x) =>
                log_error("ERROR",x)
            )

        download_raw: () ->
            link = document.createElement('a')
            link.setAttribute('href', window.location.origin + '/degust/' + this.code + '/' + 'csv')
            suffix = if this.settings.csv_format then ".csv" else ".tsv"
            link.setAttribute('download', this.experimentName + suffix)
            document.body.appendChild(link)
            link.click()
            link.remove()

        get_predef: () ->
            this.predef_gene_lists = await GeneListAPI.get_all_geneLists()
            console.log(this.predef_gene_lists)
        downloadR: () ->
            rcode = ""
            p = this.backend.request_r_code(this.dge_method, this.sel_conditions, this.sel_contrast, this.dge_parameters)
            p.then((d) =>
                element = document.createElement('a');
                element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(d));
                element.setAttribute('download', "degust.R");
                element.style.display = 'none';
                document.body.appendChild(element);
                element.click();
                document.body.removeChild(element);

            )


    mounted: () ->
        this.init()
        # TODO : ideally just this component, not window.  But, need ResizeObserver to do this nicely
        window.addEventListener('resize', () => this.$emit('resize'))
