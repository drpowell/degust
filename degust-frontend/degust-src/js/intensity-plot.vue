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
<div>
        <bar-graph class='bar-graph'
                :tot-width='700'
                :tot-height='500'
                :margin-t='50'
                :margin-r='50'
                :margin-l='90'
                :margin-b='75'
                :title='"Density of Raw and Imputed Values"'
                :title-y='-20'
                x-label="Log2 Intensity"
                y-label="Total"
                :rotate-labels='true'
                :x-domain='[0,35]'
                :x-ordinal='false'
                :fill='colourSample'
                :data='bin_intensity'
                :stacked='true'
                >
        </bar-graph>
</div>
</template>

<script lang='coffee'>

barGraph = require('./bar-graph.vue').default

module.exports =
    components:
        barGraph: barGraph
    props:
        geneData: null
        colour:
            type: Function
            default: d3.scale.category10()
    computed:
        count_columns: () ->
            this.geneData.columns_by_type('count')
        imputed_columns: () ->
            this.geneData.columns_by_type('imputed')
        gather_intensity: () ->
            #Raw counts need to be log2'd
            group_intensity = (col_type) =>
                data = this.geneData
                row = data.get_data().map((rw) ->
                    names = data.columns_by_type(col_type).map((i) -> i.idx)
                    names.map((el) -> rw[el])
                )
                [].concat.apply([], row)
            count_intensity = group_intensity("count").filter((el) -> el != 0).map((el) -> Math.log(el) * Math.LOG2E)
            imputed_itensity = group_intensity("imputed").map((el) -> Number(el))
            {count:count_intensity, imputed:imputed_itensity}
        bin_intensity: () ->
            data = this.gather_intensity
            maxval = Math.ceil(Math.max.apply(null, data.imputed))
            manualBins = [0..(maxval)]
            count_bins = d3.layout.histogram().bins(manualBins)(data.count).map((el) -> {lbl: el.x, val: el.y, width: el.dx,  group: "count"})
            imputed_bins = d3.layout.histogram().bins(manualBins)(data.imputed).map((el) -> {lbl: el.x, val: el.y, width: el.dx, group: "imputed"})
            imputed_bins.map((el, i) -> el.val = (el.val - count_bins[i].val))
            [count_bins, imputed_bins]

        barGraphData: () ->
            Vue.noTrack(this.bin_intensity)
    methods:
        colourSample: () ->
            this.colour(this.bin_intensity.map((el) -> el.group))
</script>
