<style scoped>

.outer {
    position: absolute;
    top: 80px;
    left: 50%;
}

.hist {
    position: relative;
    left: -50%;
}

</style>

<template>
    <div class='outer' v-if="showQc!=''">
        <edit-overlay class='hist'
                      :enabled='true'
                      :show-buttons='false'
                      @bg-click='$emit("close")'
                      >
                      <div>
            <pvalue-histogram v-if='showQc=="pvalue"'
                              :gene-data='geneData'>
            </pvalue-histogram>
            <library-size-plot v-if='showQc=="library-size"'
                              :gene-data='geneData'
                              :colour='colour'
                              >
            </library-size-plot>
            <expression-boxplot v-if='showQc=="expression-boxplot"'
                                :gene-data='geneData'
                                :colour='colour'
                                :is-rle='false'
                                :get-normalized='getNormalized'
                                :avail-normalization='availNormalization'
                                >
            </expression-boxplot>
            <expression-boxplot v-if='showQc=="rle-boxplot"'
                                :gene-data='geneData'
                                :colour='colour'
                                :is-rle='true'
                                :get-normalized='getNormalized'
                                :avail-normalization='availNormalization'
                                >
            </expression-boxplot>
            <cv-histogram v-if='showQc=="cv-plot"'
                          :gene-data='geneData'
                          :colour='colour'
                          >
            </cv-histogram>
            <quant-histogram v-if='showQc=="quant-plot"'
                          :gene-data='geneData'
                          :colour='colour'
                          >
            </quant-histogram>
            <intensity-histogram v-if='showQc=="intensity-plot"'
                          :gene-data='geneData'
                          :colour='colour'
                          >
            </intensity-histogram>
            <imputed-heatmap v-if='showQc=="imputed-heatmap"'
                          :gene-data='geneData'
                          >
            </imputed-heatmap>
        </div>
        </edit-overlay>
    </div>
</template>

<script lang='coffee'>

editOverlay = require('./edit-overlay.vue').default
pvalueHistogram = require('./pvalue-histogram.vue').default
librarySizePlot = require('./library-size-plot.vue').default
expressionBoxplot = require('./expression-boxplot.vue').default
cvHistogram = require('./cv-plot.vue').default
quantHistogram = require('./quantified-histogram.vue').default
intensityHistogram = require('./intensity-plot.vue').default
imputedHeatmap = require('./imputed-heatmap.vue').default


module.exports =
    name: 'qc'
    components:
        editOverlay: editOverlay
        pvalueHistogram: pvalueHistogram
        expressionBoxplot: expressionBoxplot
        librarySizePlot: librarySizePlot
        cvHistogram: cvHistogram
        quantHistogram: quantHistogram
        intensityHistogram: intensityHistogram
        imputedHeatmap: imputedHeatmap
    props:
        showQc: null
        geneData: null
        getNormalized: null
        availNormalization: null
        colour:
            type: Function
            default: d3.scale.category10()
    mounted: () ->
        document.addEventListener("keydown", (e) =>
            if (this.showQc!='' && e.keyCode == 27)
                this.$emit('close')
        )

</script>
