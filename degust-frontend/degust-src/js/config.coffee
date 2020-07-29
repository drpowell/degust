

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


input_type_option_row = (val) ->
    res = input_type_options.filter((r) -> r.key == val)
    if res.length>0
        res[0]
    else
        ''

flds_optional = ["ec_column","link_column","link_url","min_counts", "min_columns", "min_cpm",
                 "min_cpm_samples","fdr_column","avg_column","skip_header_lines"]
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
    res.contrasts ?= []
    res.filter_rows ?= []

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
        res.input_type = input_type_option_row(res.input_type)
        if res.input_type==''
            delete res.input_type

    #console.log("server model",mdl,res)
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
               {value: 'voom-weights', label: 'Voom (sample weights)'},
               {value: 'voom-topconfects', label: 'Topconfects (voom)'}
              ]

input_type_options = [{key: 'counts', label: 'RNA-seq counts'},
                      {key: 'maxquant', label: 'MaxQuant output'},
                      {key: 'preanalysed', label: 'Pre-analysed logFC'},
                     ]

Multiselect = require('vue-multiselect').default
Modal = require('./modal.vue').default
deleteModal = require('./modal-deleteData.vue').default
about = require('./about.vue').default
slickTable = require('./slick-table.vue').default
contrasts = require('./contrasts.vue').default
renameSamples = require('./rename-samples.vue').default
navbar = require('./navbar.vue').default

module.exports =
    components:
        Multiselect: Multiselect
        Modal: Modal
        deleteModal: deleteModal
        about: about
        slickTable: slickTable
        contrasts: contrasts
        renameSamples: renameSamples
        navbar: navbar
    data: () ->
        settings:
            info_columns: []     # Columns that have been selected as "info columns"
            fc_columns: []
            input_type: null
            contrasts: []
        csv_data: ""
        asRows: []
        column_names: []          # This is all column names available from the csv
        table_columns: []         # All csv columns for display in the slick table
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
        editing_contrast: null
        renaming_samples: false
        show_deleteModal: false

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
            this.settings.skip_header_lines
            this.csv_data
            Date.now()
        is_pre_analysed: () ->
            this.settings.input_type?.key == 'preanalysed'
        is_rnaseq_counts: () ->
            this.settings.input_type?.key == 'counts'
        is_maxquant: () ->
            this.settings.input_type?.key == 'maxquant'
        column_names_may_hide: () ->
            nice = this.settings.nice_names || {}
            this.column_names.filter((c) -> !nice[c]? || !nice[c].hide)

    watch:
        'settings.name': () -> document.title = this.settings.name
        csv_data: () ->
            # Guess the format, if we haven't set a name yet
            if !this.settings.name?
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
            if this.settings.skip_header_lines
                asRows = asRows[this.settings.skip_header_lines..]
            if asRows?
                asRows = asRows.map((row) -> row.map((entry) -> entry.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')))
            column_keys = asRows.shift()
            column_keys ?= []

            # No config has been saved yet, so let's guess!
            if !this.settings.name?
                if column_keys.includes('Peptide counts (razor+unique)')
                    this.settings.input_type = input_type_option_row('maxquant')
                else if column_keys.includes('FDR') || column_keys.includes('adj.P.Val')
                    this.settings.input_type = input_type_option_row('preanalysed')
                else
                    this.settings.input_type = input_type_option_row('counts')

            this.table_columns = column_keys.map((key,i) ->
                id: key
                name: key
                field: i
                sortable: false
                )
            #Filter columns to only the ones we want
            if this.is_maxquant
                this.table_columns = this.table_columns.filter( (obj) ->
                    obj.name.match("Protein ID|^LFQ.*|Potential contaminant|Reverse|Peptide counts \\(razor\\+unique\\)"))
            this.column_names = this.table_columns.map( (obj) -> obj.name )

            # No config has been saved yet, so let's guess any useful columns
            if !this.settings.name?
                if this.is_maxquant
                    this.settings.info_columns = this.column_names.filter((c) -> ['Protein IDs','Peptide counts (razor+unique)'].includes(c))

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
        deleteDataset: () ->
            this.show_deleteModal = true
        addSettingFilter: () ->
            this.settings.filter_rows ?= []
            this.settings.filter_rows.push({column:null, regexp:''})
        delSettingFilter: (idx) ->
            this.settings.filter_rows.splice(idx,1)
        destroy: () ->
            delete_url = this.orig_settings.delete_url
            token = this.orig_settings.tok
            $.ajax(
                type: "DELETE"
                beforeSend: (xhr) -> xhr.setRequestHeader('X-CSRF-Token', token)
                url: delete_url
            ).complete((e) =>
                if e.status == 200
                    window.location.href = '/visited' #uses JS to redirect instead of Ruby. May want to replace?
                else
                    console.log("Error")
                    this.modal.msgs_class = 'alert alert-danger'
                    this.modal.msgs = ["Failed : #{e.responseText}"]
                    this.modal.view = false
                    this.modal.show = true
                    this.modal.reload_on_close=true
            )

        revert: () ->
            this.settings = from_server_model(this.orig_settings.settings)
        check_errs: () -> #TODO: Add error checking for other user inputs
            errs = this.check_conditon_names()
            if !(valid_int(this.settings.min_counts))
                errs.push("Invalid min read count value")
            if !(valid_float(this.settings.min_cpm))
                errs.push("Invalid CPM value")
            if !(valid_int(this.settings.min_cpm_samples))
                errs.push("Invalid 'in at least samples'")
            if !(valid_int(this.settings.skip_header_lines))
                errs.push("Invalid 'Skip header lines'")
            this.settings.contrasts.forEach((c) =>
                if (c.column.length != this.settings.replicates.length)
                    errs.push("Contrast '"+c.name+"' does not match number of samples")
            )
            errs = errs.concat(this.check_duplicate_columns())
            errs

        check_duplicate_columns: () ->
            errs=[]
            # Get all the column names from the configured replicates
            used_cols = this.settings.replicates.map((rep) -> rep.cols).reduce(((x, y) -> x.concat(y)), [])
            # Get the  duplicate columns from the CSV
            duplicate_cols = []
            for col, index in this.column_names
                if this.column_names.lastIndexOf(col) > index
                    duplicate_cols.push(col)
            # Check if any of the duplicate columns are actually used
            for col in duplicate_cols
                if (col in this.settings.info_columns) || (col in used_cols)
                    errs.push("Cannot use column '#{col}' as it is duplicated in the csv file")
            errs

        check_conditon_names: () ->
            invalid = []
            rep_names = this.settings.replicates.map((rep) -> rep.name)
            if (new Set(rep_names).size != rep_names.length)
                invalid.push("Duplicate condition name")

            for name in rep_names
                if (name in this.column_names)
                    invalid.push("ERROR : Cannot use condition name '#{name}', it is already a column name")
                if (name=="")
                    invalid.push("Missing condition name")
            this.settings.contrasts.forEach((c) =>
                if (c.name in this.column_names)
                    invalid.push("ERROR : Cannot use contrast name '#{c.name}', it is already a column name")
                if (c.name in rep_names)
                    invalid.push("ERROR : Contrast name '#{c.name}' is already a condition name")
                if (c.name=="")
                    invalid.push("Missing contrast name")
            )

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
            this.settings.contrasts.forEach((c) -> c.column.push(0))
        del_replicate: (idx) ->
            this.settings.replicates.splice(idx, 1)
            this.settings.contrasts.forEach((c) -> c.column.splice(idx, 1))
        move_replicate: (idx, dir) ->
            if idx+dir>=0 && idx+dir<this.settings.replicates.length
                r = this.settings.replicates.splice(idx,1)
                this.settings.replicates.splice(idx+dir, 0, r[0])
                this.settings.contrasts.forEach((c) ->
                    r = c.column.splice(idx, 1)
                    c.column.splice(idx+dir, 0, r[0])
                )

        nice_name: (col) ->
            nice = this.settings.nice_names
            if nice? && (col of nice) && nice[col].name
                nice[col].name
            else
                col
        rename_samples: () ->
            this.renaming_samples = true
        close_rename_samples: () ->
            this.renaming_samples = false
        apply_rename_samples: (conf) ->
            if conf
                this.$set(this.settings, "nice_names", conf)
            this.close_rename_samples()

        add_contrast: () ->
            r = {name:''}
            this.settings.contrasts.push(r)
            this.edit_contrast(this.settings.contrasts.length-1)
        close_contrast: () ->
            this.settings.contrasts[this.editing_contrast.idx] = this.$refs.contrast_editor.contrast
            this.editing_contrast = null
        edit_contrast: (idx) ->
            r = this.settings.contrasts[idx]
            r.idx = idx
            this.editing_contrast = r  # This displays the edit modal
        delete_contrast: () ->
            this.settings.contrasts.splice(this.editing_contrast.idx,1)
            this.editing_contrast=null

        guess_condition_name: (rep, force_guess) ->
            if (!force_guess && rep.name!="" && rep.cols.length>0)
                return
            n = common_prefix(rep.cols.map((c) => this.nice_name(c)))
            rep.name = n
        script: (typ) ->
            "#{this.code}/#{typ}"

        get_csv_data: () ->
            d3.text(this.script("partial_csv"), "text/csv", (err,dat) =>
                if err
                    document.getElementsByClassName('div.container').insertAdjacentText('beforeend', 'ERROR : #{err.statusText}')
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
                    this.get_csv_data()
                    if this.orig_settings['extra_menu_html']
                        document.getElementById('right-navbar-collapse').insertAdjacentHTML('beforeend', this.orig_settings['extra_menu_html'])
                )

        tip: (txt) ->
            {content:txt, placement:'right'}

        download_raw: () ->
            $.ajax(
                type: "GET"
                url: window.location.origin + '/degust/' + this.code + '/' + 'csv'
            ).done((x) =>
                # Generate download link from: https://stackoverflow.com/q/2897619
                pom = document.createElement('a')
                pom.setAttribute('href', 'data:text/plain;charset=utf-8,' + x)
                pom.setAttribute('download', this.settings.name)
                if document.createEvent
                    event = document.createEvent('MouseEvents')
                    event.initEvent('click', true, true)
                    pom.dispatchEvent(event)
                else
                    pom.click()
                    document.body.appendChild(link)
                    link.click()
                    link.remove()
            ).fail((x) =>
                log_error("ERROR", x)
            )

    mounted: ->
        this.get_settings()
