<style src="../../node_modules/vue-multiselect/dist/vue-multiselect.min.css"></style>
<style>
    @media (min-width: 1400px) {
      .container {
        width: 1380px;
      }
    }

    .multiselect__option {padding: 5px; font-size: 12px; min-height: auto;}
    .multiselect__content-wrapper { border: thin solid black;}
    .multiselect--active {  z-index: 3; }  /* Make it above the slickgrid elements */
</style>

<template>
  <div v-if='single_only'>
      <compare-single :inputCode='global_code'
                      :inputSettings='global_settings'
                      >
      </compare-single>
  </div>
  <div v-else class='container'>
      <h2>Compare Multiple Datasets</h2>


      <div v-if='redirect'>
        <a :href='redirect'>You must log in to use this page</a>
      </div>


      <div v-else>
        <button type='button' class="btn btn-primary pull-right" v-if='!show_small'
                @click='datasets.forEach((d) => d.show_large=false)'>
            Back
        </button>

        <div class='row'>
          <compare-compact v-for='(dataset,idx) in datasets'
                        :class='column_width'
                        :show-large='dataset.show_large'
                        :show-small='show_small'
                        :code='dataset.code'
                        :experiment-list='experiment_list'
                        :id='idx'
                        :genes-highlight='genes_highlight[idx]'
                        @code='(code) => dataset.code=code'
                        @remove='remove_dataset(idx)'
                        @large='dataset.show_large = $event'
                        @update='(component) => update_dataset(idx,component)'
                        @brush='(genes) => brush_dataset(idx,genes)'
                        >
          </compare-compact>
        </div>

        <div v-if='show_small'>
          <button type='button' class="btn btn-primary" @click='add_dataset()'>
            Add data set
          </button>

          <hr/>

          <div v-if='merged_rows'>
            <div class='row'>
              <div class='col-sm-4'>
                <div class='row'>
                  <label>X axis</label>
                  <multiselect v-model="x_column" :options='plot_columns' label='name' :allow-empty="false" :searchable="false" :close-on-select="true" :show-labels="false" placeholder="--- Required ---" />
                </div>
                <div class='row'>
                  <label>Y axis</label>
                  <multiselect v-model="y_column" :options='plot_columns' label='name' :allow-empty="false" :searchable="false" :close-on-select="true" :show-labels="false" placeholder="--- Required ---" />
                </div>
              </div>
              <div v-if='x_column && y_column' class='col-sm-4'>
                <scatter-plot
                        :data='merged_rows'
                        :x-column='ma_plot_x_column' :y-column='ma_plot_y_column'
                        :brush-enable='true'
                        :canvas='true'
                        :size='function() {return 2}'
                        style='height: 300px; width: 300px;'
                        :highlight='merged_genes_highlight'
                        >
                        <!-- :filter='filter'
                        :colour='colour'
                        :highlight='highlight'
                        @mouseover='show_info'
                        @mouseout='hide_info'
                        @brush='brushed' -->
                </scatter-plot>
              </div>
            </div> <!-- row -->
            <div class='row'>
              <gene-table :gene-data='merged_data'
                          :fc-columns='merged_fc_columns'
                          :rows='merged_rows'
                          :show-counts='false'
                          :show-intensity='false'
                          :useProt='false'
                          @mouseover='gene_table_hover'
                          @mouseout='gene_table_nohover'
                          >
              </gene-table>
            </div>
          </div> <!-- if merged_rows -->
        </div> <!-- if show_small -->
      </div>
  </div>
</template>

<script lang='coffee' src="./compare-main.coffee"></script>
