

# TODO - re-enable warnings
warnings = () ->
    # Check fdr-column
    el = $('#fdr-column').siblings('.text-error')
    el.text('')
    if !mod_settings.analyze_server_side && !mod_settings.fdr_column
        $(el).text('You must specify the False Discovery Rate column')

    # Check avg-column
    el = $('#avg-column').siblings('.text-error')
    el.text('')
    if !mod_settings.analyze_server_side && !mod_settings.avg_column
        $(el).text('You must specify the Average Expression column')

valid_int = (n) ->
    !isNaN(n) && (n % 1 == 0)

valid_float = (n) ->
    !isNaN(n)

# Return the longest common prefix of the list of strings passed in
common_prefix = (lst) ->
    return "" if lst.length==0
    lst = lst.slice(0).sort()
    tem1 = lst[0]
    s = tem1.length
    tem2 = lst.pop()
    while(s && (tem2.indexOf(tem1) != 0 || "_-".indexOf(tem1[s-1])>=0))
        tem1 = tem1.substring(0, --s)
    tem1

$(document).ready(() -> setup_nav_bar() )
$(document).ready(() -> $('[title]').tooltip())


flds_optional = ["ec_column","link_column","link_url","min_counts","min_cpm",
                 "min_cpm_samples","fdr_column","avg_column"]
from_server_model = (mdl) ->
    res = $.extend(true, {}, mdl)

    # Optional fields, we use empty string to mean missing
    for c in flds_optional
        res[c] ?= ""

    # init_select goes into replicates
    new_reps = []
    for r in res.replicates
        new_reps.push(
            id: Math.random()   # Only used for list ordering, not really important
            name: r[0]
            cols: r[1]
            init: r[0] in res.init_select
            factor: r[0] in res.hidden_factor
        )
    res.replicates = new_reps

    if res.dge_method?
        res.dge_method = dge_methods.filter((r) -> r.value == res.dge_method)
        if res.dge_method.length>0
        then res.dge_method=res.dge_method[0]
        else delete res.dge_method

    # Deal with old "analyze_server_side" option
    if res.analyze_server_side? && !res.input_type?
        res.input_type = if res.analyze_server_side then 'counts' else 'preanalysed'

    # Convert "input_type" setting to row from options
    if res.input_type?
        res.input_type = input_type_options.filter((r) -> r.key == res.input_type)
        if res.input_type.length>0
        then res.input_type=res.input_type[0]
        else delete res.input_type

    console.log("server model",mdl,res)
    res

to_server_model = (mdl) ->
    res = $.extend(true, {}, mdl)
    res.info_columns ?= []
    res.fc_columns ?= []
    # Optional fields, we use empty string to mean missing
    for c in flds_optional
        if res[c]==""
            delete res[c]
    res.init_select = []
    res.hidden_factor = []
    new_reps = []
    for r in res.replicates
        new_reps.push([r.name, r.cols])
        if r.init
            res.init_select.push(r.name)
        if r.factor
            res.hidden_factor.push(r.name)
    res.replicates = new_reps
    if res.fdrThreshold==""
        delete res.fdrThreshold
    if res.dge_method?
        res.dge_method = res.dge_method.value
    if !res.dge_method?
        delete res.dge_method
    if res.input_type?
        res.input_type = res.input_type.key
    if !res.input_type?
        delete res.input_type

    res

dge_methods = [{value: 'voom', label: 'Voom/Limma'},
               {value: 'edgeR-quasi', label: 'edgeR quasi-likelihood'},
               {value: 'edgeR', label: 'edgeR'},
               {value: 'voom-weights', label: 'Voom (sample weights)'}
              ]

input_type_options = [{key: 'counts', label: 'RNA-seq counts'},
                      {key: 'maxquant', label: 'MaxQuant output'},
                      {key: 'preanalysed', label: 'Pre-analysed logFC'},
                     ]

Multiselect = require('vue-multiselect').default
Modal = require('modal-vue').default
about = require('./about.vue').default
slickTable = require('./slick-table.vue').default

module.exports =
    components:
        Multiselect: Multiselect
        Modal: Modal
        about: about
        slickTable: slickTable
    data: ->
        settings:
            info_columns: []
            fc_columns: []
        csv_data: ""
        asRows: []
        columns_info: []
        table_columns: []
        orig_settings:
            is_owner: false
        advanced: false
        modal:
            show: false
            msgs: ""
            msgs_class: ""
        dge_methods: dge_methods
        show_about: false
        input_type_options: input_type_options
    computed:
        code: () ->
            get_url_vars()["code"]
        view_url: () ->
            "compare.html?code=#{this.code}"
        can_lock: () ->
            this.orig_settings.is_owner
        grid_watch: () ->
            this.settings.csv_format
            this.settings.input_type
            this.csv_data
            Date.now()
        is_pre_analysed: () ->
            this.settings.input_type?.key == 'preanalysed'
        is_rnaseq_counts: () ->
            this.settings.input_type?.key == 'counts'
        is_maxquant: () ->
            this.settings.input_type?.key == 'maxquant'

    watch:
        'settings.name': () -> document.title = this.settings.name
        csv_data: () ->
            # Guess the format, if we haven't set a name yet
            if !this.settings.name? || this.settings.name==''
                this.settings.csv_format = this.csv_data.split("\t").length<10

        grid_watch: () ->
            this.parse_csv()
            #this.grid.updateRowCount()
            #this.grid.render()
    methods:

        #Refactored to accept MaxQuant tsv and make the preview table
        parse_csv: () ->
            #console.log "Parsing!" that
            asRows = null
            if this.settings.csv_format
                asRows = d3.csv.parseRows(this.csv_data)
            else
                asRows = d3.tsv.parseRows(this.csv_data)
            column_keys = asRows.shift()
            column_keys ?= []

            this.table_columns = column_keys.map((key,i) ->
                id: key
                name: key
                field: i
                sortable: false
                )
            #Filter columns to only the ones we want
            if this.is_maxquant
                this.table_columns = this.table_columns.filter( (obj) ->
                    obj.name.match("Protein\x20ID|^LFQ.*|Potential\x20contaminant|Reverse|Peptide\x20counts\x20\\(razor\\+unique\\)"))
            this.columns_info = this.table_columns.map( (obj) -> obj.name )
            asRows.forEach((r,i) -> r.id = i)
            this.asRows = Vue.noTrack(asRows)

        closeModal: () ->
            if this.modal.reload_on_close
                window.location = window.location
            else
                this.modal.show=false

        save: () ->
            err = this.check_errs()
            if err.length>0
                this.modal.msgs_class = 'alert alert-danger'
                this.modal.msgs = err
                this.modal.show = true
                this.modal.view = false
                this.modal.reload_on_close=false
                return

            this.modal.msgs_class = 'alert alert-info'
            this.modal.msgs = ["Saving..."]
            this.modal.show = true
            this.modal.reload_on_close=false

            to_send = to_server_model(this.settings)
            $.ajax(
                type: "POST"
                url: this.script("settings")
                data: {settings: JSON.stringify(to_send)}
                dataType: 'json'
            ).done((x) =>
                this.modal.msgs_class = 'alert alert-success'
                this.modal.msgs = ["Save successful"]
                this.modal.view = true
                this.modal.show = true
                this.modal.reload_on_close=true
            ).fail((x) =>
                log_error("ERROR",x)
                this.modal.msgs_class = 'alert alert-danger'
                this.modal.msgs = ["Failed : #{x.responseText}"]
                this.modal.view = false
                this.modal.show = true
                this.modal.reload_on_close=true
            )
        revert: () ->
            this.settings = from_server_model(this.orig_settings.settings)
        check_errs: () ->
            errs = this.check_conditon_names()
            if !(valid_int(this.settings.min_counts))
                errs.push("Invalid min read count value")
            if !(valid_float(this.settings.min_cpm))
                errs.push("Invalid CPM value")
            if !(valid_int(this.settings.min_cpm_samples))
                errs.push("Invalid 'in at least samples'")
            errs
        check_conditon_names: () ->
            invalid = []
            for rep in this.settings.replicates
                if (rep.name in this.columns_info)
                    invalid.push("ERROR : Cannot use condition name '#{rep.name}', it is already a column name")
                if (rep.name=="")
                    invalid.push("Missing condition name")
            invalid

        # Return the condition names for the given replicate name.  Used in displaying options
        conditions_for_rep: (name) ->
            res=[]
            this.settings.replicates.forEach((rep) ->
                if (name in rep.cols)
                    res.push(if rep.name=="" then "<unnamed>" else rep.name)
            )
            res

        add_replicate: () ->
            r = {id:Math.random(),name:"",cols:[],init:false,factor:false}
            this.settings.replicates.push(r)
            if this.settings.replicates.length<=2
                r.init=true
        del_replicate: (idx) ->
            this.settings.replicates.splice(idx, 1)
        move_replicate: (idx, dir) ->
            if idx+dir>=0 && idx+dir<this.settings.replicates.length
                r = this.settings.replicates.splice(idx,1)
                this.settings.replicates.splice(idx+dir, 0, r[0])

        selected_reps: (rep) ->
            n = common_prefix(rep.cols)
            rep.name = n
        script: (typ) ->
            "#{this.code}/#{typ}"

        get_csv_data: () ->
            d3.text(this.script("partial_csv"), "text/csv", (err,dat) =>
                if err
                    $('div.container').text("ERROR : #{err.statusText}")
                    return
                this.csv_data = dat
            )
        get_settings: () ->
            if !this.code?
                log_error("No code defined")
            else
                d3.json(this.script("settings"), (err,json) =>
                    if err
                        log_error "Failed to get settings!",err.statusText
                        return
                    this.orig_settings=json
                    this.revert()
                    if this.orig_settings['extra_menu_html']
                        $('#right-navbar-collapse').append(this.orig_settings['extra_menu_html'])
                )

    mounted: ->
        this.get_settings()
        this.get_csv_data()
