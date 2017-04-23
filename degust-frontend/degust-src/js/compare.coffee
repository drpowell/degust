num_loading = 0
start_loading = () ->
    num_loading += 1
    $('#loading').show()
    $('#dge-pc,#dge-ma,#dge-pca').css('opacity',0.4)
done_loading = () ->
    num_loading -= 1
    if num_loading==0
        $('#loading').hide()
        $('#dge-pc,#dge-ma,#dge-pca').css('opacity',1)

html_escape = (str) ->
    $('<div/>').text(str).html()

class WithoutBackend
    constructor: (@settings, @process_dge_data) ->
        $('.conditions').hide()
        $('.config').hide()
        $('a.show-r-code').hide()

    request_init_data: () ->
        start_loading()
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
        @process_dge_data(data, @settings.columns)
        done_loading()

    request_kegg_data: (callback) ->
        log_error("Get KEGG data not supported without backend")

# BackendCommon - used by both WithBackendNoAnalysis and WithBackendAnalysis
class BackendCommon
    @config_url: () ->
        "config.html?code=#{window.my_code}"

    @script: (typ,params) ->
        "#{window.my_code}/#{typ}" + if params then "?#{params}" else ""

    constructor: (@settings, configured, @full_settings) ->
        # Ensure we have been configured!
        if !configured
            window.location = BackendCommon.config_url()

        if @settings['config_locked'] && !@full_settings['is_owner']
            $('a.config').hide()
        else
            $('a.config').removeClass('hide')
            $('a.config').attr('href', BackendCommon.config_url())

    request_kegg_data: (callback) ->
        d3.tsv(BackendCommon.script('kegg_titles'), (err,ec_data) ->
            log_info("Downloaded kegg : rows=#{ec_data.length}")
            log_debug("Downloaded kegg : rows=#{ec_data.length}",ec_data,err)
            callback(ec_data)
        )

class WithBackendNoAnalysis
    constructor: (@settings, @process_dge_data, @full_settings) ->
        @backend = new BackendCommon(@settings, @settings.fc_columns.length > 0, @full_settings)

        $('.conditions').hide()
        $('a.show-r-code').hide()

    request_kegg_data: (callback) ->
        @backend.request_kegg_data(callback)

    request_init_data: () ->
        req = BackendCommon.script("csv")
        start_loading()
        d3.text(req, (err, dat) =>
            log_info("Downloaded DGE CSV: len=#{dat.length}")
            done_loading()
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

            @process_dge_data(data, data_cols)
        )

class WithBackendAnalysis
    constructor: (@settings, @process_dge_data, @full_settings) ->
        @backend = new BackendCommon(@settings, @settings.replicates.length > 0, @full_settings)

        $('.conditions').show()
        $('a.show-r-code').show()

        $('select#dge-method').click((e) => @_select_sample())

    request_kegg_data: (callback) ->
        @backend.request_kegg_data(callback)

    request_init_data: () ->
        @_init_condition_selector()

    _extra_info: (extra) ->
        html = ""
        if extra.sample_weights?
            $('.weights-toggle').show()
            html = $("<div></div>")
            for i in [0...extra.sample_weights.length]
                html.append("<div><span class='name'>#{extra.samples[i]}</span><span class='val'>#{extra.sample_weights[i]}</span></div>")
        else
            $('.weights-toggle').hide()
        $('.weights').html(html)

    _request_dge_data: () ->
        columns = @current_selection
        return if columns.length <= 1

        # load csv file and create the chart
        method = @_get_dge_method()
        req = BackendCommon.script("dge","method=#{method}&fields=#{encodeURIComponent(JSON.stringify columns)}")
        start_loading()
        d3.json(req, (err, json) =>
            done_loading()

            if err
                log_error(err)
                return

            if (json.error?)
                log_error("Error doing DGE",json.error)
                $('div#error-modal .modal-body pre.error-msg').text(json.error.msg)
                $('div#error-modal .modal-body pre.error-input').text(json.error.input)
                $('div#error-modal').modal()
                return

            data = d3.csv.parse(json.csv);
            log_info("Downloaded DGE counts : rows=#{data.length}")
            log_debug("Downloaded DGE counts : rows=#{data.length}",data,err)
            log_info("Extra info : ",json.extra)

            @_extra_info(json.extra)


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

            @process_dge_data(data, data_cols)
        )

    request_r_code: (callback) ->
        columns = @current_selection
        method = @_get_dge_method()
        req = BackendCommon.script("dge_r_code","method=#{method}&fields=#{encodeURIComponent(JSON.stringify columns)}")
        d3.text(req, (err,data) ->
            log_debug("Downloaded R Code : len=#{data.length}",data,err)
            callback(data)
        )

    _get_dge_method: () ->
        $('select#dge-method option:selected').val()

    _set_dge_method: (method) ->
        $('select#dge-method').val(method)

    # Display the sample selector.
    _select_sample: (e) ->
        current_dge_method = @_get_dge_method()

        # EditList will do nothing if the specified element is already in "edit" mode
        new EditList(
            elem: '.conditions'
            apply: () => @_update_samples()
            cancel: () =>
                @_set_selected_cols(@current_selection)
                @_set_dge_method(current_dge_method)
        )

    # This reads the state of the form checkboxes and stores it in @current_selection
    # Note we do it this way rather than a getter because we can't seem to capture
    # a checkbox change event *before* the checkbox is updated.  So, doing it
    # this way allows us to "cancel" an checkbox changes after the fact
    _update_selected_cols: () ->
        cols = []
        # Create a list of conditions that are selected
        $('#files input:checked').each( (i, n) =>
            name = $(n).data('rep')
            cols.push(name)
        )
        @current_selection = cols

    _set_selected_cols: (cols) ->
        $('#files input:checkbox').each( (i, n) =>
            name = $(n).data('rep')
            $(n).prop('checked', name in cols)
        )

    _update_samples: () ->
        @_update_selected_cols()
        @_request_dge_data()

    _init_condition_selector: () ->
        init_select = @settings['init_select'] || []
        hidden_factor = @settings['hidden_factor'] || []
        hidden_div = $("<div></div>")
        $.each(@settings.replicates, (i, rep) =>
            name = rep[0]
            if name in hidden_factor
                hidden_div.append($("<div><label>#{name}</label></div>"))
            else
                div = $("""<label>
                            <input type='checkbox' title='Select this condition' data-placement='right'> #{name}
                           </label>
                        """)
                $("#files").append(div)
                $("input",div).data('rep',name)
        )
        $("#files input").change((e) => @_select_sample(e))
        if hidden_factor.length>0
            $('#hidden-factors').append(hidden_div)
            $('#hidden-factors').show()

        @_set_selected_cols(init_select)
        @_update_samples()

blue_to_brown = d3.scale.linear()
  .domain([0,0.05,1])
  .range(['brown', "steelblue", "steelblue"])
  .interpolate(d3.interpolateLab)

colour_cat20 = d3.scale.category20().domain([1..20])
colour_by_ec = (ec_col) ->
    (row) -> colour_cat20(row[ec_col])

colour_by_pval = (col) ->
    (d) -> blue_to_brown(d[col])

# Globals for widgets
parcoords = null
ma_plot = null
pca_plot = null
current_plot = null    # parcoords OR ma_plot OR pca_plot depending which is active
gene_expr = null

gene_table = null
kegg = null
heatmap = null

g_data = null
g_backend = null
requested_kegg = false


# Globals for settings
show_counts = 'no'   # Possible values 'yes','no','cpm'
fdrThreshold = 1
fcThreshold = 0

fdrSlider = null
fcSlider = null
pcaDimsSlider = null

numGenesThreshold = 50
numGenesSlider = null    # Need a handle on this to update number of genes
skipGenesThreshold = 50
skipGenesSlider = null   # Need a handle on this to update number of genes
pcaDimension = 1
pcaDimsSlider = null

searchStr = ""
kegg_filter = []
h_runfilters = null
g_tour_setup = false
g_colour_by_parent = d3.scale.category10()

kegg_mouseover = (obj) ->
    ec = obj.id
    rows = []
    ec_col = g_data.column_by_type('ec')
    return if ec_col==null
    for row in g_data.get_data()
        rows.push(row) if row[ec_col.idx] == ec
    current_plot.highlight(rows)

# highlight parallel coords (and/or kegg)
gene_table_mouseover = (item) ->
    current_plot.highlight([item])
    ec_col = g_data.column_by_type('ec')
    kegg.highlight(item[ec_col.idx])
    heatmap.highlight([item])
    gene_expr.select(g_data, [item])

gene_table_mouseout = () ->
    current_plot.unhighlight()
    $('#gene-info').html('')
    kegg.unhighlight()
    heatmap.unhighlight()


# Rules for guess best info link based on some ID
guess_link_info =
    [{re: /^ENS/, link: 'http://ensembl.org/Multi/Search/Results?q=%s;site=ensembl'},
     {re: /^CG/, link: 'http://flybase.org/cgi-bin/uniq.html?species=Dmel&cs=yes&db=fbgn&caller=genejump&context=%s'},
     {re: /^/, link: 'http://www.ncbi.nlm.nih.gov/gene/?&term=%s'},
    ]

# Guess the link using the guess_link_info table
guess_link = (info) ->
    return if !info?
    for o in guess_link_info
        return o.link if info.match(o.re)
    return null

# Open a page for the given gene.  Use either the defined link or guess one.
# The "ID" column can be specified as 'link' otherwise the first 'info' column is used
gene_table_dblclick = (item) ->
    cols = g_data.columns_by_type(['link'])
    if cols.length==0
        cols = g_data.columns_by_type(['info'])
    if cols.length>0
        info = item[cols[0].idx]
        link = if settings.link_url? then settings.link_url else guess_link(info)
        log_debug("Dbl click.  Using info/link",info,link)
        if link?
            link = link.replace(/%s/, info)
            window.open(link)
            window.focus()

get_default_plot_typ = () ->
    if g_data.columns_by_type(['fc','primary']).length>2
        'parcoords'
    else
        'ma'

may_set_plot_var = (typ) ->
    if typ == get_default_plot_typ()
        set_hash_var({plot: null})
    else
        set_hash_var({plot: typ})

update_link = () ->
    set_hash_var(get_state())

update_from_link = (force_update) ->
    set_state(get_hash_vars(), force_update)


set_plot = (typ, force_update) ->
    switch typ
        when 'mds'       then plot=pca_plot; activate=activate_pca_plot
        when 'ma'        then plot=ma_plot; activate=activate_ma_plot
        when 'parcoords' then plot=parcoords; activate=activate_parcoords
    if (current_plot != plot || force_update)
        activate()
        may_warn_mds()

may_warn_mds = () ->
    if (current_plot == pca_plot)
        $('.fdr-fld').toggleClass('warning', fdrThreshold<1)
        $('.fc-fld').toggleClass('warning', fcThreshold>0)
    else
        $('.fdr-fld').toggleClass('warning', false)
        $('.fc-fld').toggleClass('warning', false)

get_state = () ->
    plot =
        if $('#select-pc').hasClass('active')
            'parcoords'
        else if $('#select-ma').hasClass('active')
            'ma'
        else if $('#select-pca').hasClass('active')
            'mds'
    state = {}
    state.plot = plot
    def = (val, def) -> if val==def then null else val
    state.show_counts = def(show_counts,'no')
    state.fdrThreshold = def(fdrThreshold,1)
    state.fcThreshold = def(fcThreshold,0)
    fc_rel = $('select#fc-relative option:selected').val()
    state.fc_relative = def(+fc_rel, 0)
    if plot=='mds'
        state.numGenesThreshold = numGenesThreshold
        state.skipGenesThreshold = skipGenesThreshold
        state.pcaDimension = pcaDimension
    # if plot=='ma'
    #     ex = ma_plot.brush_extent()
    state.searchStr = def(searchStr,"")

    state.single_gene_expr = def($('#select-single-gene-expr').hasClass('active'), false)

    return state

set_state = (state, force_update) ->
    if state.plot?
        set_plot(state.plot, force_update)
    else
        set_plot(get_default_plot_typ(), force_update)

    # if state.plot=='ma' && state.ma_brush?
    #     ma_plot.brush_extent(state.ma_brush)

    fdrSlider.set_val(state.fdrThreshold, true) if state.fdrThreshold?
    fcSlider.set_val(state.fcThreshold, true) if state.fcThreshold?

    if state.show_counts?
        $('select#show-counts').val(state.show_counts)
        update_flags()
        gene_table.invalidate()

    numGenesSlider.set_val(+state.numGenesThreshold, true) if state.numGenesSlider?
    skipGenesSlider.set_val(+state.skipGenesSlider, true) if state.skipGenesSlider?
    pcaDimsSlider.set_val(+state.pcaDimension, true) if state.pcaDimension?

    update_search_str(state.searchStr, true) if (state.searchStr?)

    if state.single_gene_expr
        activate_single_gene_expr()
    else
        activate_options()


activate_options = () ->
    $('#select-options').addClass('active')
    $('#select-single-gene-expr').removeClass('active')
    $('.options').show()
    $('.single-gene-expr').hide()

activate_single_gene_expr = () ->
    $('#select-single-gene-expr').addClass('active')
    $('#select-options').removeClass('active')
    $('.options').hide()
    $('.single-gene-expr').show()

activate_parcoords = () ->
    may_set_plot_var('parcoords')
    current_plot = parcoords
    $('#dge-ma,#dge-pca').hide()
    $('#dge-pc').show()
    $('#select-pc').addClass('active')
    $('#select-ma,#select-pca').removeClass('active')
    $('.ma-fc-col-opt').hide()
    $('.pca-opts').hide()
    heatmap.enabled(true)
    update_data()

activate_ma_plot = () ->
    may_set_plot_var('ma')
    current_plot = ma_plot
    $('#dge-pc,#dge-pca').hide()
    $('#dge-ma').show()
    $('#select-ma').addClass('active')
    $('#select-pc,#select-pca').removeClass('active')
    $('.ma-fc-col-opt').show()
    $('.pca-opts').hide()
    heatmap.enabled(true)
    update_data()

activate_pca_plot = () ->
    may_set_plot_var('mds')
    current_plot = pca_plot
    $('#dge-pc,#dge-ma').hide()
    $('#dge-pca').show()
    $('#select-pca').addClass('active')
    $('#select-pc,#select-ma').removeClass('active')
    $('.ma-fc-col-opt').hide()
    heatmap.enabled(false)
    $('.pca-opts').show()
    numGenesSlider.set_max(100, 1, g_data.get_data().length, true)
    skipGenesSlider.set_max(0, 0, g_data.get_data().length, true)

    update_data()

calc_max_parcoords_width = () ->
    w = $('.container').width()
    w -= $('.conditions').outerWidth(true) if $('.conditions').is(':visible')
    w -= $('div.filter').outerWidth(true) if $('div.filter').is(':visible')

init_charts = () ->
    gene_table = new GeneTable(
        elem: '#grid'
        elem_info: '#grid-info'
        sorter: do_sort
        mouseover: gene_table_mouseover
        mouseout: gene_table_mouseout
        dblclick: gene_table_dblclick
        filter: gene_table_filter
        )

    parcoords = new ParCoords(
        elem: '#dge-pc'
        width: calc_max_parcoords_width()
        filter: expr_filter
        )

    ma_plot = new MAPlot(
        elem: '#dge-ma'
        filter: expr_filter
        brush_enable: true
        canvas: true
        height: 300
        width: 600
        )
    ma_plot.on("mouseover.main", (rows) -> heatmap.highlight(rows); gene_expr.select(g_data, rows))
    ma_plot.on("mouseout.main", () -> heatmap.unhighlight())

    pca_plot = new GenePCA(
        elem: '#dge-pca'
        filter: expr_filter
        colour: g_colour_by_parent
        sel_dimension: (d) => pcaDimsSlider.set_val(+d, true)
        params: () ->
            skip: +skipGenesThreshold
            num: +numGenesThreshold
            dims: [+pcaDimension, +pcaDimension+1, +pcaDimension+2]
            plot_2d3d: $('select#mds-2d3d option:selected').val()

        )
    pca_plot.on("top_genes", (top) =>
        gene_table.set_data(top)
        heatmap.schedule_update(top)
    )

    kegg = new Kegg(
        elem: 'div#kegg-image'
        mouseover: kegg_mouseover
        mouseout: () -> current_plot.unhighlight()
        )

    # update grid on brush
    parcoords.on("brush", (d) ->
        gene_table.set_data(d)
        heatmap.schedule_update(d)
    )
    ma_plot.on("brush", (d) ->
        gene_table.set_data(d)
        heatmap.schedule_update(d)
    )

    # Used to reorder the heatmap columns by the parcoords order
    order_columns_by_parent = (columns, parent) ->
        pos = {}
        for i in [0...parent.length]
            pos[parent[i]] = i
        new_cols = columns.slice()
        new_cols.sort((a,b) ->
            if pos[a.parent]==pos[b.parent]
                0
            else if pos[a.parent] < pos[b.parent]
                -1
            else
                1
        )
        new_cols

    parcoords.on("render", () ->
        return if !heatmap.columns
        dim_names = parcoords.dimension_names()
        names = parcoords.dimensions().map((c) -> dim_names[c])
        new_cols = order_columns_by_parent(heatmap.columns, names)
        heatmap.reorder_columns(new_cols)
    )

    #Heatmap
    heatmap = new Heatmap(
        elem: '#heatmap'
        show_elem: '.show-heatmap'
    )
    heatmap.on("mouseover", (d) ->
        current_plot.highlight([d])
        msg = ""
        for col in g_data.columns_by_type(['info'])
          msg += "<span class='lbl'>#{col.name}: </span><span>#{d[col.idx]}</span>"
        $('#heatmap-info').html(msg)
        gene_expr.select(g_data, [d])
    )
    heatmap.on("mouseout", (d) ->
        current_plot.unhighlight()
        $('#heatmap-info').html("")
    )
    heatmap.on("need_update", () -> update_data())

    gene_expr = new GeneExpression(
        elem: '.single-gene-expr'
        width: 233
        colour: g_colour_by_parent
    )


comparer = (x,y) -> (if x == y then 0 else (if x > y then 1 else -1))

do_sort = (args) ->
    column = g_data.column_by_idx(args.sortCol.field)
    gene_table.sort((r1,r2) ->
        r = 0
        x=r1[column.idx]; y=r2[column.idx]
        if column.type in ['fc_calc']
            r = comparer(Math.abs(x), Math.abs(y))
        else if column.type in ['fdr']
            r = comparer(x, y)
        else
            r = comparer(x,y)
        r * (if args.sortAsc then 1 else -1)
    )

set_gene_table = (data) ->
    column_keys = g_data.columns_by_type(['info','fdr','p'])
    column_keys = column_keys.concat(g_data.columns_by_type('fc_calc'))
    columns = column_keys.map((col) ->
        hsh =
            id: col.idx
            name: col.name
            field: col.idx
            sortable: true
            formatter: (i,c,val,m,row) ->
                if col.type in ['fc_calc']
                    fc_div(val, col, row)
                else if col.type in ['fdr','p']
                    if val<0.01 then val.toExponential(2) else val.toFixed(2)
                else
                    val
        if col.type in ['fdr','p']
            hsh.width = 70
            hsh.maxWidth = 70
        hsh
    )
    gene_table.set_data(data, columns)

fc_div = (n, column, row) ->
    colour = if n>0.1 then "pos" else if n<-0.1 then "neg" else ""
    countStr = ""
    if show_counts=='yes'
        count_columns = g_data.assoc_column_by_type('count',column.name)
        vals = count_columns.map((c,i) -> "<span>#{row[c.idx]}</span>")
        countStr = "<span class='counts'>(#{vals.join(" ")})</span>"
    else if show_counts=='cpm'
        count_columns = g_data.assoc_column_by_type('count',column.name)
        vals = count_columns.map((c) ->
            tot = g_data.get_total(c)
            val = (1000000 * row[c.idx]/tot).toFixed(1)
            "<span>#{val}</span>"
        )
        countStr = "<span class='counts'>(#{vals.join(" ")})</span>"
    "<div class='#{colour}'>#{n.toFixed(2)}#{countStr}</div>"


gene_table_filter = (item) ->
    return true if searchStr == ""
    for col in g_data.columns_by_type('info')
        str = item[col.idx]
        return true if str? && typeof str == 'string' &&
                       str.toLowerCase().indexOf(searchStr)>=0
    false

# Filter to decide which rows to plot on the parallel coordinates widget
expr_filter = (row) ->
    if fcThreshold>0
        # Filter using largest FC between any pair of samples
        fc = g_data.columns_by_type('fc').map((c) -> row[c.idx])
        extent_fc = d3.extent(fc.concat([0]))
        if Math.abs(extent_fc[0] - extent_fc[1]) < fcThreshold
            return false

    # Filter by FDR
    pval_col = g_data.columns_by_type('fdr')[0]
    return false if row[pval_col.idx] > fdrThreshold

    # If a Kegg pathway is selected, filter to that.
    if kegg_filter.length>0
        ec_col = g_data.column_by_type('ec')
        return row[ec_col.idx] in kegg_filter

    true

update_search_str = (str, fillbox=false) ->
    searchStr = str.toLowerCase()
    $(".tab-search input").toggleClass('active', searchStr != "")
    gene_table.refresh()
    if (fillbox)
        $(".tab-search input").val(str)

init_search = () ->
    $(".tab-search input").keyup (e) ->
                    Slick.GlobalEditorLock.cancelCurrentEdit()
                    this.value = "" if e.which == 27     # Clear on "Esc"
                    update_search_str(this.value)

# Format data as ODF as used by GenePattern
# http://software.broadinstitute.org/cancer/software/genepattern/file-formats-guide#ODF
odf_fmt = (cols,rows) ->
    hdr = ["ODF 1.0",
           "HeaderLines=4",
           "Model= Dataset",
           "DataLines="+rows.length,
           "COLUMN_TYPES: "+cols.map((c)->if c.type=='info' then "String" else "double").join("\t"),
           "COLUMN_NAMES: "+cols.map((c)->c.name).join("\t"),
    ].concat(rows.map((r) -> r.join("\t"))).join("\n")

do_download = (fmt) ->
    items = gene_table.get_data()
    return if items.length==0
    cols = g_data.columns_by_type(['info','fc_calc','count','fdr','avg'])
    count_cols = g_data.columns_by_type('count')
    keys = cols.map((c) -> c.name).concat(count_cols.map((c) -> c.name+" CPM"))
    rows = items.map( (r) ->
        cpms = count_cols.map((c) -> (r[c.idx]/(g_data.get_total(c)/1000000.0)).toFixed(3))
        cols.map( (c) -> r[c.idx] ).concat(cpms)
    )
    mimetype = 'text/csv'
    switch fmt
        when 'csv' then filename='degust.csv'; result=d3.csv.format([keys].concat(rows))
        when 'tsv' then filename='degust.tsv'; result=d3.tsv.format([keys].concat(rows))
        when 'odf'
            mimetype = 'text/plain'
            filename='degust.odf'
            cols_all = cols.concat(count_cols.map((c) -> {type:'cpm', name: c.name+" CPM"}))
            result=odf_fmt(cols_all, rows)

    # In future, look at this library : https://github.com/eligrey/FileSaver.js
    link = document.createElement("a")
    link.setAttribute("href", window.URL.createObjectURL(new Blob([result], {type: mimetype})))
    link.setAttribute("download", filename)
    document.body.appendChild(link)
    link.click()
    link.remove()


init_download_link = () ->
    $('a#csv-download').on('click', (e) -> e.preventDefault(); do_download('csv'))
    $('a.download-csv').on('click', (e) -> e.preventDefault(); do_download('csv'))
    $('a.download-tsv').on('click', (e) -> e.preventDefault(); do_download('tsv'))
    $('a.download-odf').on('click', (e) -> e.preventDefault(); do_download('odf'))

init_genesets = () ->
    $('.geneset-save').on('click', () ->
        console.log "SAVE"
    )
    $('.geneset-search input.search').autocomplete(
        source: "/gene-sets"
        minLength: 2
        select: ( event, ui ) ->
            if ui.item
                d3.json("/gene-sets/#{ui.item.id}", (err, json) ->
                    console.log "JSON", ui, json
                )
    );

redraw_plot = () ->
    current_plot.brush()

init_slider = () ->
    # wire up the slider to apply the filter to the model
    fdrSlider = new Slider(
          id: "#fdrSlider"
          input_id: "input.fdr-fld"
          step_values: [0, 1e-6, 1e-5, 1e-4, 0.001, .01, .02, .03, .04, .05, 0.1, 1]
          val: fdrThreshold
          validator: (v) ->
             n = Number(v)
             !(isNaN(n) || n<0 || n>1)
          on_change: (v) ->
            Slick.GlobalEditorLock.cancelCurrentEdit()
            if (fdrThreshold != v)
                window.clearTimeout(h_runfilters)
                h_runfilters = window.setTimeout(redraw_plot, 10)
                fdrThreshold = v
                may_warn_mds()
    )
    $('.shortcut-fdr a').click((e) -> e.preventDefault(); fdrSlider.set_val($(this).data('val'), true))

    fcSlider = new Slider(
          id: "#fcSlider"
          input_id: "input.fc-fld"
          step_values: (Number(x.toFixed(2)) for x in [0..5] by 0.01)
          val: fcThreshold
          validator: (v) ->
             n = Number(v)
             !(isNaN(n) || n<0)
          on_change: (v) ->
             Slick.GlobalEditorLock.cancelCurrentEdit()
             if (fcThreshold != v)
               window.clearTimeout(h_runfilters)
               h_runfilters = window.setTimeout(redraw_plot, 10)
               fcThreshold = v
               may_warn_mds()
    )
    $('.shortcut-fc a').click((e) -> e.preventDefault(); fcSlider.set_val($(this).data('val'), true))

    numGenesSlider = new Slider(
          id: "#numGenesSlider"
          input_id: "input.num-genes-fld"
          val: numGenesThreshold
          validator: (v) ->
             n = Number(v)
             !(isNaN(n) || n<0)
          on_change: (v) ->
             Slick.GlobalEditorLock.cancelCurrentEdit()
             if (numGenesThreshold != v)
               window.clearTimeout(h_runfilters)
               h_runfilters = window.setTimeout(redraw_plot, 10)
               numGenesThreshold = v
    )
    skipGenesSlider = new Slider(
          id: "#skipGenesSlider"
          input_id: "input.skip-genes-fld"
          val: skipGenesThreshold
          validator: (v) ->
             n = Number(v)
             !(isNaN(n) || n<0)
          on_change: (v) ->
             Slick.GlobalEditorLock.cancelCurrentEdit()
             if (skipGenesThreshold != v)
               window.clearTimeout(h_runfilters)
               h_runfilters = window.setTimeout(redraw_plot, 10)
               skipGenesThreshold = v
    )
    pcaDimsSlider = new Slider(
          id: "#pcaDimsSlider"
          input_id: "input.pca-dims-fld"
          step_values: [1..10]
          val: pcaDimension
          fmt: (v) -> v+" vs "+(v+1)
          validator: (v) ->
             n = Number(v)
             !(isNaN(n) || n<0)
          on_change: (v) ->
            if (pcaDimension != v)
                window.clearTimeout(h_runfilters)
                h_runfilters = window.setTimeout(redraw_plot, 10)
                pcaDimension = v
    )
    $('#fc-relative').change((e) ->
        update_data()
    )
    $('#ma-fc-col').change((e) ->
        update_data()
    )
    $('#show-counts').change((e) ->
        update_flags()
        gene_table.invalidate()
    )
    $('#mds-2d3d').change((e) ->
        redraw_plot()
    )

calc_kegg_colours = () ->
    ec_dirs = {}
    ec_col = g_data.column_by_type('ec')
    return if ec_col==null
    fc_cols = g_data.columns_by_type('fc_calc')[1..]
    for row in g_data.get_data()
        ec = row[ec_col.idx]
        continue if !ec
        for col in fc_cols
            v = row[col.idx]
            dir = if v>0.1 then "up" else if v<-0.1 then "down" else "same"
            ec_dirs[ec]=dir if !ec_dirs[ec]
            ec_dirs[ec]='mixed' if ec_dirs[ec]!=dir
    return ec_dirs

kegg_selected = () ->
    code = $('select#kegg option:selected').val()
    title = $('select#kegg option:selected').text()

    set_filter = (ec) ->
        kegg_filter = ec
        update_data()

    if !code
        set_filter([])
    else
        ec_colours = calc_kegg_colours()
        kegg.load(code, ec_colours, set_filter)
        $('div#kegg-image').dialog({width:500, height:600, title: title, position: {my: "right top", at:"right top+60", of: $('body')} })

process_kegg_data = (ec_data) ->
    return if requested_kegg
    requested_kegg = true
    opts = "<option value=''>--- No pathway selected ---</option>"

    have_ec = {}
    ec_col = g_data.column_by_type('ec')
    for row in g_data.get_data()
        have_ec[row[ec_col.idx]]=1

    ec_data.sort((a,b) ->
        a=a.title.toLowerCase()
        b=b.title.toLowerCase()
        if a==b then 0 else if a<b then -1 else 1
    )
    ec_data.forEach (row) ->
        num=0
        for ec in row.ec.split(" ").filter((s) -> s.length>0)
            num++ if have_ec[ec]
        if num>0
            opts += "<option value='#{row.code}'>#{row.title} (#{num})</option>"
    $('select#kegg').html(opts)
    $('.kegg-filter').show()

process_dge_data = (data, columns) ->
    g_data = new GeneData(data, columns)

    # Setup FC "relative" pulldown
    opts = ""
    for col,i in g_data.columns_by_type(['fc','primary'])
        opts += "<option value='#{i}'>#{html_escape col.name}</option>"
    opts += "<option value='-1'>Average</option>"
    $('select#fc-relative').html(opts)

    # Setup MA-plot pulldown
    opts = ""
    for col,i in g_data.columns_by_type(['fc','primary'])
        opts += "<option value='#{i}' #{if i==1 then 'selected' else ''}>#{html_escape col.name}</option>"
    $('select#ma-fc-col').html(opts)

    if g_data.column_by_type('ec') == null
        $('.kegg-filter').hide()
    else if !requested_kegg
        g_backend.request_kegg_data(process_kegg_data)

    if g_data.columns_by_type('count').length == 0
        $('.show-counts-opt').hide()
        $('#select-pca').hide()
    else
        $('.show-counts-opt').show()
        $('#select-pca').show()

    update_from_link(true)

    # First time throught?  Setup the tutorial tour
    if !g_tour_setup
        g_tour_setup = true
        setup_tour(if settings.show_tour? then settings.show_tour else true)

update_flags = () ->
    show_counts = $('select#show-counts option:selected').val()

# Called whenever the data is changed, or the "checkboxes" are modified
update_data = () ->
    update_flags()

    # Set the 'relative' column
    fc_relative = $('select#fc-relative option:selected').val()
    if fc_relative<0
        fc_relative = 'avg'
    else
        fc_relative = g_data.columns_by_type(['fc','primary'])[fc_relative]
    g_data.set_relative(fc_relative)

    dims = g_data.columns_by_type('fc_calc')
    pval_col = g_data.column_by_type('fdr')

    if current_plot == parcoords
        extent = ParCoords.calc_extent(g_data.get_data(), dims)
        parcoords.update_data(g_data.get_data(), dims, extent, colour_by_pval(pval_col.idx))
    else if current_plot == ma_plot
        ma_fc = $('select#ma-fc-col option:selected').val()
        ma_fc = g_data.columns_by_type(['fc','primary'])[ma_fc].name
        fc_col = g_data.columns_by_type('fc_calc').filter((c) -> c.name == ma_fc)[0]
        ma_plot.update_data(g_data.get_data(),
                            g_data.columns_by_type('avg')[0],
                            fc_col,
                            colour_by_pval(pval_col.idx),
                            g_data.columns_by_type('info'),
                            pval_col
                            )
    else if current_plot == pca_plot
        cols = g_data.columns_by_type('fc_calc').map((c) -> c.name)
        count_cols = g_data.columns_by_type('count').filter((c) -> cols.indexOf(c.parent)>=0)
        pca_plot.update_data(g_data, count_cols)

    set_gene_table(g_data.get_data())

    # Update the heatmap
    if heatmap.enabled()
        if (!heatmap.show_replicates)
            heatmap_dims = g_data.columns_by_type('fc_calc_avg')
            centre=true
        else
            count_cols = dims.map((c) -> g_data.assoc_column_by_type('count',c.name))
            count_cols =[].concat.apply([], count_cols)
            heatmap_dims = Normalize.normalize(g_data, count_cols)
            centre=true
        heatmap.update_columns(g_data, heatmap_dims, centre)

    # Ensure the brush callbacks are called (updates heatmap & table)
    current_plot.brush()

show_r_code = () ->
    g_backend.request_r_code((d) ->
        $('div#code-modal .modal-body pre').text(d)
        $('div#code-modal').modal()
    )

render_page = (template) ->
    # Show the main html
    opts =
        asset_base: settings.asset_base || ''
        home_link: settings.home_link || '/'

    body = $(template(opts))
    $('#replace-me').replaceWith(body)
    $('#main-loading').hide()
    setup_nav_bar()
    $('[title]').tooltip()

render_main_page = () -> render_page(require("../templates/compare-body.hbs"))
render_fail_page = () -> render_page(require("../templates/fail.hbs"))

init_page = (use_backend) ->
    render_main_page()

    g_data = new GeneData([],[])

    if use_backend
        if settings.analyze_server_side
            g_backend = new WithBackendAnalysis(settings, process_dge_data, full_settings)
        else
            g_backend = new WithBackendNoAnalysis(settings, process_dge_data, full_settings)
    else
        g_backend = new WithoutBackend(settings, process_dge_data)


    title = settings.name || "Unnamed"
    $(".exp-name").text(title)
    document.title = title

    fdrThreshold = settings['fdrThreshold'] if settings['fdrThreshold'] != undefined
    fcThreshold  = settings['fcThreshold']  if settings['fcThreshold'] != undefined

    if full_settings?
        if full_settings['extra_menu_html']
            $('#right-navbar-collapse').append(full_settings['extra_menu_html'])

    $("select#kegg").change(kegg_selected)

    $('#select-pc a').click((e) ->  e.preventDefault(); set_plot('parcoords'))
    $('#select-ma a').click((e) ->  e.preventDefault(); set_plot('ma'))
    $('#select-pca a').click((e) -> e.preventDefault(); set_plot('mds'))
    $('#select-options a').click((e) ->  e.preventDefault(); activate_options())
    $('#select-single-gene-expr a').click((e) -> e.preventDefault(); activate_single_gene_expr())

    $('a.show-r-code').click((e) -> e.preventDefault(); show_r_code())
    $('a.update-link').click((e) -> e.preventDefault(); update_link())

    $('a.p-value-histogram').click((e) -> e.preventDefault(); QC.pvalue_histogram(g_data))
    $('a.bargraph-libsize').click((e) -> e.preventDefault(); QC.library_size_bargraph(g_data, g_colour_by_parent))
    $('a.expression-boxplot').click((e) -> e.preventDefault(); QC.expression_boxplot(g_data, g_colour_by_parent))

    init_charts()
    init_search()
    init_slider()
    init_download_link()
    init_genesets()

    g_backend.request_init_data()

    #$(window).bind( 'hashchange', update_from_link )
    $(window).bind('resize', () -> heatmap.resize())

init = () ->
    code = get_url_vars()["code"]
    if !code?
        init_page(false)
    else
        window.my_code = code
        $.ajax({
            type: "GET",
            url: BackendCommon.script("settings"),
            dataType: 'json'
        }).done((json) ->
            window.full_settings = json
            window.settings = json.settings
            init_page(true)
         ).fail((x) ->
            log_error "Failed to get settings!",x
            render_fail_page()
            pre = $("<pre></pre>")
            pre.text("Error failed to get settings : #{x.responseText}")
            $('.error-msg').append(pre)
        )


$(document).ready(() -> init() )
