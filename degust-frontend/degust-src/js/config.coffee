
script = (typ) -> "#{window.my_code}/#{typ}"

# mod_settings will contain a copy of the current settings
mod_settings = null
reset_settings = () ->
    mod_settings = $.extend(true, {}, settings)

data = null
grid = null
asRows = null
column_keys = null

init_table = () ->
    options =
      enableCellNavigation: false
      enableColumnReorder: false
      multiColumnSort: false
      forceFitColumns: true

    grid = new Slick.Grid("#grid", [], [], options)

    update_data()

csv_or_tab = () -> $('.fmt:checked').val()

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

valid_int = (str) ->
    str!='' && parseInt(str).toString() == str

valid_float = (str) ->
    !isNaN(parseFloat(str))

optional_number = (obj, fld, str) ->
    if valid_int(str)
        obj[fld] =  parseInt(str)
    else
        delete obj[fld]

optional_float = (obj, fld, str) ->
    if valid_float(str)
        obj[fld] =  parseFloat(str)
    else
        delete obj[fld]

check_conditon_names = (settings) ->
    invalid = []
    for rep in settings.replicates
        invalid.push(rep[0]) if (rep[0] in column_keys)
    if (invalid.length == 0)
        false
    else
        msgs = invalid.map((c) -> "ERROR : Cannot use condition name '#{c}', it is column name")
        msgs.join("<br/>")

save = (ev) ->
    ev.preventDefault()
    mod_settings.name = $("input.name").val()
    mod_settings.primary_name = $("input.primary").val()
    mod_settings.link_url = $("input.link-url").val()
    if mod_settings.link_url.length==0
        delete mod_settings.link_url
    conditions_to_settings()
    mod_settings.csv_format = csv_or_tab()=='CSV'

    err = check_conditon_names(mod_settings)
    if err
        $('#saving-modal .modal-body').html('<div class="alert alert-danger">' + err + '</div>')
        $('#saving-modal').modal({'backdrop': true, 'keyboard' : true})
        $('#saving-modal .view').hide()
        $('#saving-modal .modal-footer').show()
        $('#saving-modal #close-modal').click( () -> $('#saving-modal').modal('hide'))
        return

    optional_number(mod_settings, "min_counts", $("input.min-counts").val())
    optional_float(mod_settings, "min_cpm", $("input.min-cpm").val())
    optional_number(mod_settings, "min_cpm_samples", $("input.min-cpm-samples").val())

    $('#saving-modal').modal({'backdrop': 'static', 'keyboard' : false})
    $('#saving-modal .modal-body').html("Saving...")
    $('#saving-modal .modal-footer').hide()

    #console.log mod_settings
    $.ajax({
        type: "POST",
        url: script("settings"),
        data: {settings: JSON.stringify(mod_settings)},
        dataType: 'json'
    }).done((x) ->
        $('#saving-modal .modal-body').html("<div class='alert alert-success'>Save successful.</div>")
        $('#saving-modal .view').show()
     ).fail((x) ->
        log_error("ERROR",x)
        $('#saving-modal .modal-body').html("Failed : #{x.responseText}")
        $('#saving-modal .view').hide()
     ).always(() ->
        $('#saving-modal').modal({'backdrop': true, 'keyboard' : true})
        $('#saving-modal .modal-footer').show()
        $('#saving-modal #close-modal').click( () -> window.location = window.location)
     )

col_id = (n) ->
    column_keys.indexOf(n)

set_multi_select = (el, opts, selected) ->
    selected ||= []
    $(el).html(opts)
    $.each(selected, (i,col) -> $("option[value='#{col_id col}']",el).attr('selected','selected'))
    $(el).multiselect('refresh')

update_data = () ->
    return if !data

    if mod_settings['extra_menu_html']
        $('#right-navbar-collapse').append(mod_settings['extra_menu_html'])

    title = mod_settings.name || "Unnamed"
    $(".exp-name").text(title)
    document.title = title

    $("input.name").val(mod_settings.name || "")
    $("input.primary").val(mod_settings.primary_name || "")
    $("input.link-url").val(mod_settings.link_url || "")
    if mod_settings.hasOwnProperty('min_counts')
        $("input.min-counts").val(mod_settings.min_counts)
    if mod_settings.hasOwnProperty('min_cpm')
        $("input.min-cpm").val(mod_settings.min_cpm)
    if mod_settings.hasOwnProperty('min_cpm_samples')
        $("input.min-cpm-samples").val(mod_settings.min_cpm_samples)

    asRows = null
    switch csv_or_tab()
        when 'TAB' then asRows = d3.tsv.parseRows(data)
        when 'CSV' then asRows = d3.csv.parseRows(data)
        else asRows = []

    [column_keys,asRows...] = asRows

    opts = ""
    $.each(column_keys, (i, col) ->
        opts += "<option value='#{i}'>#{col}</option>"
    )

    $('select.ec-column').html("<option value='-1'>--- Optional ---</option>" + opts)
    if mod_settings.hasOwnProperty('ec_column')
        $("select.ec-column option[value='#{col_id mod_settings.ec_column}']").attr('selected','selected')

    $('select.link-column').html("<option value='-1'>--- Optional ---</option>" + opts)
    if mod_settings.hasOwnProperty('link_column')
        $("select.link-column option[value='#{col_id mod_settings.link_column}']").attr('selected','selected')

    $('select#fdr-column').html(opts)
    $('select#fdr-column').html("<option value='-1'>--- Required ---</option>" + opts)
    if mod_settings.fdr_column
        $("select#fdr-column option[value='#{col_id mod_settings.fdr_column}']").attr('selected','selected')

    $('select#avg-column').html(opts)
    $('select#avg-column').html("<option value='-1'>--- Required ---</option>" + opts)
    if mod_settings.avg_column
        $("select#avg-column option[value='#{col_id mod_settings.avg_column}']").attr('selected','selected')


    set_multi_select($('select.info-columns'), opts, mod_settings.info_columns)
    set_multi_select($('select.fc-columns'), opts, mod_settings.fc_columns)

    update_table()

    $('.condition:not(.template)').remove()
    for r in mod_settings.replicates
        [n,lst] = r
        create_condition_widget(n || 'Unknown', lst,
            n in (mod_settings['init_select'] || []),
            n in (mod_settings['hidden_factor'] || [])
            )

    $('#analyze-server-side').prop('checked', mod_settings.analyze_server_side)
    update_analyze_server_side()

    $('#config-locked').prop('checked', mod_settings.config_locked)
    $('#config-locked').prop('disabled', !full_settings.is_owner)

update_table = () ->
    columns = column_keys.map((key,i) ->
        id: key
        name: key
        field: i
        sortable: false
    )

    $('#grid-info').text("Number of columns = #{columns.length}")
    grid.setColumns(columns)
    grid.setData(asRows)
    grid.updateRowCount();
    grid.render();

    warnings()

set_guess_type = () ->
    if data.split("\t").length>20
        $('#fmt-tab').attr('checked','checked')
    else
        $('#fmt-csv').attr('checked','checked')

create_condition_widget = (name, selected, is_init, is_hidden) ->
    cond = $('.condition.template').clone(true)
    cond.removeClass('template')

    if name
        $("input.col-name",cond).val(name)
        $("input.col-name",cond).data('edited', true)
    else
        $("input.col-name",cond).data('edited', false)

    opts = ""
    $.each(column_keys, (i, col) ->
        sel = if col in selected then 'selected="selected"' else ''
        opts += "<option value='#{i}' #{sel}>#{col}</option>"
    )
    $("select.columns",cond).html(opts)
    $("select.columns",cond).multiselect(
        noneSelectedText: '-- None selected --'
        selectedList: 4
    )
    $('.init-select input',cond).prop('checked', is_init)
    $('.hidden-factor input',cond).prop('checked', is_hidden)

    $(".condition-group").append(cond)

    # Auto setting of condition name based on columns selected
    $("select",cond).change(() ->
        inp = $("input.col-name",cond)
        if inp.val()=="" || !inp.data('edited')
            lst = []
            $('select.columns option:selected',cond).each( (j,opt) ->
                n = column_keys[$(opt).val()]
                lst.push(n)
            )
            inp.val(common_prefix(lst))
    )

    # Track editing of the name.  Blanking the name out makes it "un-edited"

    $("input.col-name",cond).change(() ->
        inp = $("input.col-name",cond)
        inp.data('edited', inp.val()!="")
    )
    return cond

# Return the longest common prefix of the list of strings passed in
common_prefix = (lst) ->
    lst = lst.slice(0).sort()
    tem1 = lst[0]
    s = tem1.length
    tem2 = lst.pop()
    while(s && (tem2.indexOf(tem1) == -1 || "_-".indexOf(tem1[s-1])>=0))
        tem1 = tem1.substring(0, --s)
    tem1


init_page = () ->
    reset_settings()
    d3.text(script("partial_csv"), "text/csv", (err,dat) ->
        if err
            $('div.container').text("ERROR : #{err}")
            return
        data = dat
        set_guess_type()
        init_table()
    )

    if full_settings?
        if full_settings['extra_menu_html']
            $('#right-navbar-collapse').append(full_settings['extra_menu_html'])


    $('select.ec-column').change(() ->
        mod_settings.ec_column = +$("select.ec-column option:selected").val()
        if mod_settings.ec_column == -1
            delete mod_settings.ec_column
        else
            mod_settings.ec_column = column_keys[mod_settings.ec_column]
        warnings()
    )

    $('select.link-column').change(() ->
        mod_settings.link_column = +$("select.link-column option:selected").val()
        if mod_settings.link_column == -1
            delete mod_settings.link_column
        else
            mod_settings.link_column = column_keys[mod_settings.link_column]
        warnings()
    )

init = (settings_cb) ->
    code = get_url_vars()["code"]
    if !code?
        log_error("No code defined")
    else
        window.my_code = code
        $.ajax({
            type: "GET",
            url: script("settings"),
            dataType: 'json'
        }).done((json) ->
            window.full_settings = json
            window.settings = json.settings
            settings_cb(json)
            #init_page()
         ).fail((x) ->
            log_error "Failed to get settings!",x
        )

get_csv_data = (self) ->
    d3.text(script("partial_csv"), "text/csv", (err,dat) ->
        if err
            $('div.container').text("ERROR : #{err}")
            return
        self.csv_data = dat
    )


$(document).ready(() -> setup_nav_bar() )
#$(document).ready(() -> init() )
$(document).ready(() -> $('[title]').tooltip())

flds_optional = ["ec_column","link_column","link_url","min_counts","min_cpm","min_cpm_samples",
                 "fdr_column","avg_column"]
from_server_model = (mdl) ->
    res = $.extend(true, {}, mdl)

    # Optional fields, we use empty string to mean missing
    for c in flds_optional
        res[c] ?= ""

    # init_select goes into replicates
    new_reps = []
    for r in res.replicates
        new_reps.push(
            name: r[0]
            cols: r[1]
            init: r[0] in res.init_select
            factor: r[0] in res.hidden_factor
        )
    res.replicates = new_reps

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

    console.log("my model",mdl,res)
    res


Multiselect = require('vue-multiselect').default

module.exports =
    components: { Multiselect },
    methods:
        save: () ->
            to_server_model(this.settings)
        revert: () ->
            this.settings = from_server_model(this.orig_settings.settings)
        add_replicate: () ->
            r = {name:"",cols:[],init:false,factor:false}
            this.settings.replicates.push(r)
            if this.settings.replicates.length<=2
                r.init=true
        del_replicate: (idx) ->
            this.settings.replicates.splice(idx, 1)
        selected_reps: (rep) ->
            n = common_prefix(rep.cols)
            rep.name = n
    data: ->
        settings:
            info_columns: []
            fc_columns: []
        csv_data: ""
        orig_settings:
            is_owner: false

    computed:
        code: () ->
            get_url_vars()["code"]
        view_url: () ->
            "compare.html?code=#{this.code}"
        can_lock: () ->
            this.orig_settings.is_owner
        columns_info: () ->
            console.log "Parsing!"
            asRows = null
            if this.settings.csv_format
                asRows = d3.csv.parseRows(this.csv_data)
            else
                asRows = d3.tsv.parseRows(this.csv_data)
            [column_keys,asRows...] = asRows
            column_keys ?= []
            column_keys

    mounted: ->
        self = this
        init((new_settings) ->
            self.orig_settings=new_settings
            self.revert()
        )
        get_csv_data(self)
