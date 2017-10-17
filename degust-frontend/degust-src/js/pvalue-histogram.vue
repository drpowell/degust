<style scoped>

.bar-graph >>> .label {
    font-size: 100%;
}

.bar-graph >>> .title {
    font-weight: bold;
    font-size: 140%;
}

</style>

<template>
    <bar-graph class='bar-graph'
               :tot-width='700'
               :tot-height='500'
               :margin-t='50'
               :margin-r='50'
               :margin-l='80'
               :margin-b='50'
               title="P-value histogram"
               :title-y='-20'
               x-label="p-value"
               y-label="number"
               :x-domain='[0,1]'
               :x-ordinal='false'
               :data='barGraphData'
               >
    </bar-graph>
</template>

<script lang='coffee'>

barGraph = require('./bar-graph.vue').default

module.exports =
    components:
        barGraph: barGraph
    props:
        geneData: null
    computed:
        pval_col: () ->
            res = this.geneData.columns_by_type('p')[0]
            if !res?
                res = this.geneData.columns_by_type('fdr')[0]
            res
        pvals: () ->
            Object.freeze(this.geneData.get_data().map((r) => r[this.pval_col.idx]))
        bins: () ->
            Object.freeze(d3.layout.histogram().bins(50)(this.pvals))
        barGraphData: () ->
            Object.freeze(this.bins.map((b) -> {lbl: b.x, val: b.y, width: b.dx}))

</script>
