<style scoped>
    .ma-plot { height: 330px; }
</style>

<template>
    <scatter-plot class='ma-plot'
                  :data='data'
                  :xColumn='xColumn' :yColumn='yColumn'
                  :colour='colour'
                  :brush-enable='true' :canvas='true'
                  >
    </scatter-plot>
</template>

<script lang='coffee'>

scatter = require('./scatter-plot.vue').default

module.exports =
    components:
        scatterPlot: scatter
    props:
        data: null
        avgCol: null
        logfcCol : null
        colour: null
        info_cols: null
        fdr_col: null
    computed:
        xColumn: () ->
            xCol = this.avgCol
            if xCol?
                {name: "Ave Expr", get: (d) -> d[xCol.idx] }
            else
                null
        yColumn: () ->
            yCol = this.logfcCol
            if yCol?
                {name: "log FC", get: (d) -> d[yCol.idx] }
            else
                null

</script>
