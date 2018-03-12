compareSingle = require('./compare-single.vue').default
compareCompact = require('./compare-compact.vue').default

Multiselect = require('vue-multiselect').default
maPlot = require('./ma-plot.vue').default
scatter = require('./scatter-plot.vue').default
{ GeneData } = require('./gene_data.coffee')
geneTable = require('./gene-table.vue').default


module.exports =
    name: 'compare-main'
    components:
        compareSingle: compareSingle
        compareCompact: compareCompact
        Multiselect: Multiselect
        maPlot: maPlot
        scatterPlot: scatter
        GeneData: GeneData
        geneTable: geneTable

    data: () ->
        home_link: null
        experimentName:
            default: () -> ""

        experiment_list: []
        redirect: null
        datasets: []
        merged_data: null
        merged_fc_columns: []
        merged_rows: null
        merged_rows_selected: null
        merged_cols: null
        x_column: null
        y_column: null
        genes_highlight: []
        merged_genes_highlight: []
        merged_colour: () -> "blue"

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
            [].concat.apply([],this.merged_cols).filter((c) -> c.type == 'fc_calc')
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
        gene_table_hover: (gene) ->
            highlights = this.datasets.map((d) ->
                if !d.component?
                    []
                else
                    Vue.noTrack(d.key_mappings[gene.key])
            )
            this.genes_highlight = highlights
            if this.x_column && this.y_column && gene[this.x_column.idx]? && gene[this.y_column.idx]?
                this.merged_genes_highlight = Vue.noTrack([gene])
        gene_table_nohover: () ->
            this.genes_highlight=[]
            this.merged_genes_highlight=[]

        add_dataset: () ->
            this.datasets.push({show_large: false, code:null, gene_colour: () -> "blue"})
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
            d.gene_data.get_data().forEach((r) =>
                key = r[d.key_col.idx]
                (d.key_mappings[key] ?= []).push(r)
                if (!warn && d.key_mappings[key].length>1)
                    warn+=1
                    log_warn("Duplicate key '#{key}' in #{d.name}")
            )
            if warn>1
                log_warn("And #{warn} total duplicates in #{d.name}")

            console.log("key processing took #{Date.now() - startTime }ms")

            this.merge_datasets()

        brush_dataset: (idx, genes, empty) ->
            if idx>=0
                # Brush on a dataset scatter plot
                dataset = this.datasets[idx]
                brushed_keys = genes.map((r) -> r[dataset.key_col.idx])
                # Colour the merged dataset
                this.merged_colour = (gene) ->
                    if !empty && brushed_keys.indexOf(gene.key)>=0
                        "darkgreen"
                    else
                        "blue"
            else
                # Brush on the merged scatter plot
                brushed_keys = genes.map((r) -> r.key)

            # Now the others
            this.datasets.forEach((d,idx2) ->
                return if idx==idx2 || !d.component?
                d.gene_colour = (gene) ->
                    if !empty && brushed_keys.indexOf(gene[d.key_col.idx])>=0
                        "darkgreen"
                    else
                        "blue"
            )

            # Select subset of rows in the table
            this.merged_rows_selected = this.merged_rows.filter((gene) ->
                empty || brushed_keys.indexOf(gene.key)>=0
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
                    return if ['fc_calc','info','fdr'].indexOf(c.type)<0   # Just pertinent columns for now
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
                    all_row = (all_rows[main_keys[key]] ||= {key: key})
                    all_row.membership ||= []
                    all_row.membership[idx]=true
                    # Only keeping 1 copy of duplicate keys for now.
                    columns[idx].forEach((c) ->
                        all_row[c.idx] = r[c.orig_idx]
                    )
                )
            )
            this.merged_rows = all_rows
            this.merged_rows_selected = all_rows
            this.merged_cols = columns
            this.main_keys = main_keys

            # FIXME : Hack to pretend to use gene-data
            this.merged_data = new GeneData([],[])
            this.merged_data.data = this.merged_rows
            this.merged_data.columns = [].concat.apply([],this.merged_cols)
            this.merged_data._process_data()
            this.merged_fc_columns = this.merged_data.columns.filter((x) -> x.type == 'fc_calc')

            console.log("merge processing took #{Date.now() - startTime }ms")

    mounted: () ->
        $.ajax('/visited.json').then((response) =>
            if (response.redirect)
                this.redirect = response.redirect
            else
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
