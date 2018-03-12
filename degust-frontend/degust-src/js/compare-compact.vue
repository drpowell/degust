<style>
    @media (min-width: 1400px) {
      .container {
        width: 1380px;
      }
    }
</style>

<template>
    <div>
        <compare-single :inputCode='code.secure_id'
                        v-show='showLarge'
                        v-if='code'
                        :shown='showLarge'
                        :navbar='false'
                        @update='update'
                        ref='dataset'
                        :key='code.secure_id'
                        >
        </compare-single>

        <div class='' v-if='showSmall'>
            <div class='row'>
                <div class='col-sm-8'>
                  <multiselect :value="code" @input="(v) => $emit('code',v)"
                               :options='experimentList' track-by='secure_id' label='name' :allow-empty="false" :searchable="false" :close-on-select="true" :show-labels="false" placeholder="--- Required ---" />
                </div>
                <div class='col-sm-4'>
                    <button type='button' class="btn-xs btn-primary" @click='$emit("large",true)' :disabled='!gene_data'>
                        Edit
                    </button>
                    <button type='button' class="btn-xs btn-danger" @click='$emit("remove")'>
                        X
                    </button>
                </div>
            </div>
            <div class='row' v-if='gene_data'>
                    <ma-plot
                        :data='$refs.dataset.gene_data_rows'
                        :filter='$refs.dataset.expr_filter'
                        :filter-changed='$refs.dataset.filter_changed'
                        :logfc-col='$refs.dataset.ma_plot_fc_col'
                        :avg-col='$refs.dataset.avg_column'
                        :fdr-col='$refs.dataset.fdr_column'
                        :colour='genesColour'
                        :info-cols='$refs.dataset.info_columns'
                        :dot-size='function() {return 2}'
                        :height='250'
                        :highlight='genesHighlight'
                        @brush='(sel,empty) => $emit("brush",sel,empty)'
                        >
                        <!-- @hover-start='v => genes_hover=v' -->
                    </ma-plot>
                </div>
            </div>
        </div>
    </div>
</template>

<script lang='coffee'>

compareSingle = require('./compare-single.vue').default
Multiselect = require('vue-multiselect').default
maPlot = require('./ma-plot.vue').default

resize = require('./resize-mixin.coffee')

module.exports =
    name: 'compare-compact'
    mixins: [resize]
    components:
        compareSingle: compareSingle
        Multiselect: Multiselect
        maPlot: maPlot
    props:
        id: null
        showLarge: null
        showSmall: null
        experimentList: null
        code: null
        genesHighlight:
            default: () -> []
        genesColour:
            default: () ->
                (gene) -> "blue"
    data: () ->
        gene_data: null
    # watch:
    #     code: () ->
    #         this.gene_data=null
    methods:
        update: (gene_data) ->
            this.gene_data = gene_data
            this.$emit('update', this.$refs.dataset)
        resize: () ->
            this.$emit('resize')
</script>