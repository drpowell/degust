<style scoped>
    .volcano-plot { height: 330px; }
</style>

<template>
    <scatter-plot class='volcano-plot'
                  :data='data'
                  :xColumn='xColumn' :yColumn='yColumn'
                  :colour='colour'
                  :brush-enable='true' :canvas='true'>
    </scatter-plot>
</template>

<script lang='coffee'>

scatter = require('./scatter-plot.vue').default

module.exports =
    components:
        scatterPlot: scatter
    props:
        data: null
        logfcCol : null
        colour: null
        infoCols: null
        fdrCol: null
    computed:
        xColumn: () ->
            xCol = this.logfcCol
            if xCol?
                {name: "log FC", get: (d) => d[xCol.idx] }
            else
                null
        yColumn: () ->
            yCol = this.fdrCol
            if yCol?
                {name: "-log10 FDR", get: (d) => -Math.log10(d[yCol.idx]) }
            else
                null

</script>
