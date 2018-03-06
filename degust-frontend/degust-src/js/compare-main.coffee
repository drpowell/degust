compareSingle = require('./compare-single.vue').default

Multiselect = require('vue-multiselect').default
maPlot = require('./ma-plot.vue').default
scatter = require('./scatter-plot.vue').default


module.exports =
    name: 'compare-main'
    components:
        compareSingle: compareSingle
        Multiselect: Multiselect
        maPlot: maPlot
        scatterPlot: scatter

    data: () ->
        home_link: null
        experimentName:
            default: () -> ""

        code1: null
        code2: null
        show_code1: false
        show_code2: false
        experiment_list: []
        redirect: null
        info1: null
        info2: null
        data_merged: null

    computed:
        global_code: () -> get_url_vars()["code"]
        global_settings: () -> window.settings
        single_only: () ->
            this.global_code || Object.keys(this.global_settings).length>0

    methods:
        update1: (gene_data) ->
            this.info1 = "Set1 : Num genes = " + gene_data.get_data().length
            if this.info2
                this.update_merged()
        update2: (gene_data) ->
            this.info2 = "Set2 : Num genes = " + gene_data.get_data().length
            if this.info1
                this.update_merged()
        update_merged: () ->
            data1 = this.$refs.dataset1.gene_data
            data2 = this.$refs.dataset2.gene_data
            col1 = this.$refs.dataset1.info_columns[0]
            col2 = this.$refs.dataset1.info_columns[0]
            console.log "Merging sets using",col1,"with",col2
            keys1 = {}
            data1.get_data().forEach((r) ->
                keys1[r[col1.idx]] = r
            )
            result = []
            only2 = []
            data2.get_data().forEach((r2) ->
                r1 = keys1[r2[col2.idx]]
                if r1?
                    o = {}
                    Object.keys(r1).map((k) -> o["d1"+k] = r1[k])
                    Object.keys(r2).map((k) -> o["d2"+k] = r2[k])
                    result.push(o)
                    delete keys1[r2[col2.idx]]
                else
                    only2.push(r2)
            )
            console.log "Merged.  intersect=",result.length,"unique to dataset1=",Object.keys(keys1).length,"unique to dataset2=",only2.length
            this.data_merged = result
            xCol = this.$refs.dataset1.ma_plot_fc_col
            yCol = this.$refs.dataset2.ma_plot_fc_col
            console.log xCol
            this.xColumn= {name: "D1 "+xCol.name, get: (d) -> d["d1"+xCol.idx] }
            this.yColumn= {name: "D2 "+yCol.name, get: (d) -> d["d2"+yCol.idx] }

    mounted: () ->
        $.ajax('/visited.json').then((response) =>
            if (response.redirect)
                this.redirect = response.redirect
            else
                console.log response
                this.experiment_list = response.mine.concat(response.others)
        )

        # TODO : ideally just this component, not window.  But, need ResizeObserver to do this nicely
        window.addEventListener('resize', () => this.$emit('resize'))
