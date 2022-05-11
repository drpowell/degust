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
               :tot-width='width'
               :tot-height='500'
               :margin-t='50'
               :margin-r='50'
               :margin-l='90'
               :margin-b='200'
               title="Number of Quantified Proteins"
               :title-y='-20'
               x-label="Sample"
               y-label="Quantified Proteins"
               :rotate-labels='true'
               :x-ordinal='true'
               :fill='colourSample'
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
        colour:
            type: Function
            default: d3.scale.category10()
    computed:
        columns: () ->
            this.geneData.columns_by_type('count')
        width: () ->
            d3.min([this.columns.length*30 + 200, 700])
        quantNum: () ->
            data = this.geneData
            val = []
            this.columns.map((col) ->
                    count = 0
                    data.get_data().map((row) ->
                            count += (row[col.idx] > 0)
                    )
                    val.push(count)
            )
            this.columns.map((col, i) => {lbl: col.name, val: val[i], parent: col.parent})
        barGraphData: () ->
            Vue.noTrack(this.quantNum)
    methods:
        colourSample: (c) ->
            this.colour(c.parent)
</script>
