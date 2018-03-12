compareSingle = require('./compare-single.vue').default
compareCompact = require('./compare-compact.vue').default

Multiselect = require('vue-multiselect').default
maPlot = require('./ma-plot.vue').default
scatter = require('./scatter-plot.vue').default


module.exports =
    name: 'compare-main'
    components:
        compareSingle: compareSingle
        compareCompact: compareCompact
        Multiselect: Multiselect
        maPlot: maPlot
        scatterPlot: scatter

    data: () ->
        home_link: null
        experimentName:
            default: () -> ""

        experiment_list: []
        redirect: null
        datasets: []
        merged_rows: null
        merged_cols: null
        x_column: null
        y_column: null

    computed:
        column_width: () ->
            if this.datasets.length==0 || !this.show_small
                'col-sm-12'
            else
                'col-sm-'+(12/this.datasets.length)
        show_small: () ->
            !this.datasets.some((d) -> d.show_large)
        global_code: () -> get_url_vars()["code"]
        global_settings: () -> window.settings
        single_only: () ->
            this.global_code || Object.keys(this.global_settings).length>0
        global_multi_codes: () ->
            p = get_url_vars()["multi"] || ""
            p.split(",").filter((x) -> x.length>0)
        multi_codes: () ->
            this.datasets.map((x) -> x.code?.secure_id).filter((x) -> x && x.length>0)
        plot_columns: () ->
            [].concat.apply([],this.merged_cols).filter((c) -> c.type == 'fc')
        ma_plot_x_column: () ->
            x_col = this.x_column
            {name: x_col.name, get: (d) -> d[x_col.idx]}
        ma_plot_y_column: () ->
            y_col = this.y_column
            {name: y_col.name, get: (d) -> d[y_col.idx]}

    watch:
        column_width: () ->
            this.$emit('resize')

    methods:
        add_dataset: () ->
            this.datasets.push({show_large: false, code:null})
        remove_dataset: (idx) ->
            this.datasets.splice(idx, 1)
            this.merge_datasets()

        update_dataset: (idx, component) ->
            d = this.datasets[idx]
            d.component = component
            d.name = component.experimentName
            d.key_col = component.info_columns[0]
            d.key_mappings = {}
            d.gene_data = component.gene_data

            # Create a mapping from the key column
            startTime = Date.now()
            warn=0
            d.gene_data.get_data().forEach((r,rid) =>
                key = r[d.key_col.idx]
                (d.key_mappings[key] ?= []).push(rid)
                if (!warn && d.key_mappings[key].length>1)
                    warn+=1
                    log_warn("Duplicate key '#{key}' in #{d.name}")
            )
            if warn>1
                log_warn("And #{warn} total duplicates in #{d.name}")

            console.log("key processing took #{Date.now() - startTime }ms")

            this.merge_datasets()

        brush_dataset: (idx, genes) ->
            console.log "brush",idx,genes
            dataset = this.datasets[idx]
            keys = genes.map((r) -> r[dataset.key_col.idx])
            this.datasets.forEach((d,idx2) =>
                return if !d.component? || idx==idx2
                res = []
                keys.forEach((k) =>
                    ids = this.data_merged[this.main_keys[k]][idx2]
                    ids.forEach((id) => res.push(d.gene_data.get_data()[id]))
                )
                console.log "highlight",d.genes_highlight
                d.component.set_highlight(res)
            )

        merge_datasets: () ->
            main_keys = {}
            all_rows = []
            columns = []
            startTime = Date.now()
            # Create 'all_rows' which will contain 1 row for each item.  Each row contains 1 column for each data set
            this.datasets.forEach((d,idx) =>
                return if !d.component?
                # Add all the columns
                columns[idx] = []
                d.gene_data.columns.forEach((c) ->
                    return if ['fc','info'].indexOf(c.type)<0   # Just pertinent columns for now
                    new_col = Object.assign({}, c)
                    new_col.name = d.name + " : "+c.name
                    new_col.orig_idx = c.idx
                    new_col.idx = "ds#{idx}_"+c.idx
                    columns[idx].push(new_col)
                )
                # Now process the rows
                d.gene_data.get_data().forEach((r) ->
                    key = r[d.key_col.idx]
                    if !(key of main_keys)
                        main_keys[key] = all_rows.length
                    all_row = (all_rows[main_keys[key]] ||= {})
                    # Only keeping 1 copy of duplicate keys for now.
                    columns[idx].forEach((c) ->
                        all_row[c.idx] = r[c.orig_idx]
                    )
                )
            )
            this.merged_rows = all_rows
            this.merged_cols = columns
            this.main_keys = main_keys
            console.log("merge processing took #{Date.now() - startTime }ms")
            console.log("Union cols = ", this.merged_cols)
            console.log("Union rows = ", this.merged_rows)

    mounted: () ->
        $.ajax('/visited.json').then((response) =>
            if (response.redirect)
                this.redirect = response.redirect
            else
                console.log response
                this.experiment_list = response.mine.concat(response.others)
        )

        if this.global_multi_codes.length==0
            this.add_dataset()
            this.add_dataset()
        else
            this.global_multi_codes.forEach((c) =>
                this.add_dataset()
                this.datasets[this.datasets.length-1].code=c
            )

        # TODO : ideally just this component, not window.  But, need ResizeObserver to do this nicely
        window.addEventListener('resize', () => this.$emit('resize'))
