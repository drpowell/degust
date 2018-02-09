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
                                >
            </expression-boxplot>
            <expression-boxplot v-if='showQc=="rle-boxplot"'
                                :gene-data='geneData'
                                :colour='colour'
                                :is-rle='true'
                                >
            </expression-boxplot>
            <cv-histogram v-if='showQc=="cv-plot"'
                          :gene-data='geneData'
                          :colour='colour'
                          >
            </cv-histogram>
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


module.exports =
    name: 'qc'
    components:
        editOverlay: editOverlay
        pvalueHistogram: pvalueHistogram
        expressionBoxplot: expressionBoxplot
        librarySizePlot: librarySizePlot
        cvHistogram: cvHistogram
    props:
        showQc: null
        geneData: null
        colour:
            type: Function
            default: d3.scale.category10()
</script>
