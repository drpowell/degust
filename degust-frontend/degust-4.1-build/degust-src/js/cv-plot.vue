<style scoped>
.bar-graph>>>.label {
  font-size: 50%;
}

.bar-graph>>>.title {
  font-weight: bold;
  font-size: 70%;
}
</style>

<template>
<div>
    <div class='row' v-for="i of Math.ceil(barGraphData.length / 4)">
        <div class='container'>
        <div class='col-sm-3' v-for="graph of barGraphData.slice((i - 1) * 4, i * 4)">
            <bar-graph class='bar-graph'
                    :tot-width='340'
                    :tot-height='260'
                    :margin-t='50'
                    :margin-r='50'
                    :margin-l='80'
                    :margin-b='50'
                    :title=graph.p_label
                    :title-y='-20'
                    x-label="Variation"
                    y-label="Frequency"
                    :x-domain='[0,165]'
                    :x-ordinal='false'
                    :data=graph.val
                    >
            </bar-graph>
            <p></p>
        </div>
        </div>
    </div>
</div>
</template>

<script lang='coffee'>

barGraph = require('./bar-graph.vue').default

module.exports =
    components:
        barGraph: barGraph
    props:
        geneData: null
    computed:
        columns: () ->
            this.geneData.columns_by_type('count')

        cv: () ->
            data = this.geneData
            parents = data.columns_by_type("count").map((i) -> i.parent).filter((el, i, ar) -> ar.indexOf(el) == i)
            res = parents.map((parent) ->
                    row = data.get_data().map((rw) ->
                            names = data.assoc_column_by_type("count", parent).map((i) -> i.idx)
                            names.map((el) -> rw[el])
                            )
                    result = row.map((rw) ->
                            rw.filter((e) -> e != 0)
                            mean = d3.mean(rw)
                            seriesSum = d3.sum(rw.map((el) -> el - mean).map((e) -> e ** 2))
                            sd = Math.sqrt((1/rw.length)*seriesSum)
                            coeff = (sd/mean) * 100
                            )
            )
            val = parents.map((parent, i) -> {p_label: parent, val: res[i]})
            Vue.noTrack(res)
            Vue.noTrack(val)
        bins: () ->
            bin = []
            for value in this.cv
                bin.push( {p_label: value.p_label, val: Vue.noTrack(d3.layout.histogram().bins(50)(value.val))} )
            Vue.noTrack(bin)
        barGraphData: () ->
            res = []
            for value in this.bins
                res.push( {p_label: "CV Histogram of " + value.p_label, val: value.val.map((bin) -> {lbl: bin.x, val: bin.y, width: bin.dx}) } )
            Vue.noTrack(res)
</script>
