<style scoped>
.bar-graph>>>.label {
  font-size: 100%;
}

.bar-graph>>>.title {
  font-weight: bold;
  font-size: 140%;
}
</style>

<template>
<div>
    <div v-for="graph of barGraphData">
        <bar-graph class='bar-graph'
                :tot-width='700'
                :tot-height='500'
                :margin-t='50'
                :margin-r='50'
                :margin-l='80'
                :margin-b='50'
                title="Coefficient of Variation Histogram"
                :title-y='-20'
                x-label=""
                y-label="number"
                :x-domain='[0,150]'
                :x-ordinal='false'
                :data=graph
                >
        </bar-graph>
        <p></p>
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
    data: () ->
       arrray: ["wow", "oh"]
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
                    res = row.map((rw) -> 
                            rw.filter((e) -> e != 0)
                            mean = d3.mean(rw)
                            seriesSum = d3.sum(rw.map((el) -> el - mean).map((e) -> e ** 2))
                            sd = Math.sqrt((1/rw.length)*seriesSum)
                            coeff = (sd/mean) * 100
                            )
            )
            Vue.noTrack(res)
        bins: () ->
            bin = []
            for value in this.cv
                bin.push(Vue.noTrack(d3.layout.histogram().bins(50)(value)))
            return bin
        barGraphData: () ->
            Vue.noTrack(this.bins.map((g) -> g.map((b) -> {lbl: b.x, val: b.y, width: b.dx})))
</script>
