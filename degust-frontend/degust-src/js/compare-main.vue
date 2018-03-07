<style src="../../node_modules/vue-multiselect/dist/vue-multiselect.min.css"></style>
<style>
    @media (min-width: 1400px) {
      .container {
        width: 1380px;
      }
    }
</style>

<template>
  <div v-if='single_only'>
      <compare-single :inputCode='global_code'
                      :inputSettings='global_settings'
                      >
      </compare-single>
  </div>
  <div v-else class='container'>
      <button type='button' class="btn btn-primary pull-right"
              v-if='show_code1 || show_code2' @click='show_code1=show_code2=false'>
        Back
      </button>
      <h2>Compare Multiple</h2>
      <div v-if='redirect'>
        <a :href='redirect'>You must log in to use this page</a>
      </div>
      <div v-else>
        <compare-single :inputCode='code1.secure_id'
                        v-show='show_code1'
                        v-if='code1'
                        :navbar='false'
                        @update='update1'
                        ref='dataset1'
                        :key='"d1"+code1.secure_id'
                        >
        </compare-single>
        <compare-single :inputCode='code2.secure_id'
                        v-show='show_code2'
                        v-if='code2'
                        :navbar='false'
                        @update='update2'
                        ref='dataset2'
                        :key='"d2"+code2.secure_id'
                        >
        </compare-single>
        <div v-if='!(show_code1 || show_code2)'>
          <div class='row'>
            <label class='col-sm-1'>Dataset 1</label>
            <div class='col-sm-3'>
              <multiselect v-model="code1" :options='experiment_list' track-by='secure_id' label='name' :allow-empty="false" :searchable="false" :close-on-select="true" :show-labels="false" placeholder="--- Required ---" />
            </div>
            <a v-if='code1' @click='show_code1=true'>Show</a>
          </div>
          <div class='row'>
            <label class='col-sm-1'>Dataset 2</label>
            <div class='col-sm-3'>
              <multiselect v-model="code2" :options='experiment_list' track-by='secure_id' label='name' :allow-empty="false" :searchable="false" :close-on-select="true" :show-labels="false" placeholder="--- Required ---" />
            </div>
            <a v-if='code2' @click='show_code2=true'>Show</a>
          </div> <!-- row -->
          <div class='row'>
            <div v-if='info1' class='col-sm-3'>
              {{info1}}
              <ma-plot
                        :data='$refs.dataset1.gene_data_rows'
                        :filter='$refs.dataset1.expr_filter'
                        :filter-changed='$refs.dataset1.filter_changed'
                        :logfc-col='$refs.dataset1.ma_plot_fc_col'
                        :avg-col='$refs.dataset1.avg_column'
                        :fdr-col='$refs.dataset1.fdr_column'
                        :colour='$refs.dataset1.plot_colouring'
                        :info-cols='$refs.dataset1.info_columns'
                        :dot-size='function() {return 1}'
                        >
                        <!-- :highlight='genes_highlight'
                        @brush='set_genes_selected'
                        @hover-start='v => genes_hover=v' -->
              </ma-plot>
            </div>
            <div v-if='info2' class='col-sm-3'>
              {{info2}}
              <ma-plot
                        :data='$refs.dataset2.gene_data_rows'
                        :filter='$refs.dataset2.expr_filter'
                        :filter-changed='$refs.dataset2.filter_changed'
                        :logfc-col='$refs.dataset2.ma_plot_fc_col'
                        :avg-col='$refs.dataset2.avg_column'
                        :fdr-col='$refs.dataset2.fdr_column'
                        :colour='$refs.dataset2.plot_colouring'
                        :info-cols='$refs.dataset2.info_columns'
                        :dot-size='function() {return 1}'
                        >
                        <!-- :highlight='genes_highlight'
                        @brush='set_genes_selected'
                        @hover-start='v => genes_hover=v' -->
              </ma-plot>
            </div>
            <div v-if='data_merged' class='col-sm-3'>
              <scatter-plot
                      :data='data_merged'
                      :x-column='xColumn' :y-column='yColumn'
                      :brush-enable='true'
                      :canvas='true'
                      :size='function() {return 1}'
                      >
                      <!-- :filter='filter'
                      :colour='colour'
                      :highlight='highlight'
                      @mouseover='show_info'
                      @mouseout='hide_info'
                      @brush='brushed' -->
              </scatter-plot>
            </div>
          </div>
        </div> <!--!(show_code1 || show_code2) -->

      </div>
  </div>

</template>

<script lang='coffee' src="./compare-main.coffee"></script>
