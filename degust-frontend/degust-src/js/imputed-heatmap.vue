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
    <heatmap
            :gene-data='heatmapData'
            :dimensions='heatmapDims'
            :genes-show='genes_selected'
            :show-replicates='heatmap_show_replicates'
            @show-replicates='v => heatmap_show_replicates=v'
            :geneOrder='false'
            :width=900
            >

    </heatmap>
</div>
</template>

<script lang='coffee'>

heatmap = require('./heatmap.vue').default

module.exports =
    components:
        heatmap: heatmap
    props:
        geneData: null
        heatmap_show_replicates: false

    computed:
        genesShow: () ->
            this.fixValue.get_data()
        genes_selected: () ->
            this.fixValue.get_data()
        columns: () ->
            this.fixValue.columns_by_type('count')
        heatmapDims: () ->
            this.columns

        fixValue: () ->
            data = this.geneData

            #Don't want to modify the data object so we attempt a partial clone
            newdata = JSON.parse(JSON.stringify(data))
            #Assign accessors needed later
            newdata.get_data = data.get_data
            newdata.row_by_id = data.row_by_id
            newdata.columns_by_type = data.columns_by_type

            rem = []
            #Replace newdata's count data 1's and 0's for heatmap
            newdata.get_data().map((rw) ->
                ids = newdata.columns_by_type("count").map((i) -> i.idx)
                sum = 0
                ids.map((el) ->
                    if rw[el] > 0
                        sum += 1
                        rw[el] = 1
                    else
                        rw[el] = -1
                )
                rem.push(sum)
            )

            len = newdata.columns_by_type("count").length
            #filter out rows that are all present (no missing values)
            res = newdata.data.filter((el, i) ->
                rem[i] != len
            )
            #Replace data
            newdata.data = res
            Vue.noTrack(newdata)

        heatmapData: () ->
            Vue.noTrack(this.fixValue)
</script>
