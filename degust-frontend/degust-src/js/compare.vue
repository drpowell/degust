<style>
    .slider-control { display: inline-block; }
    a.sm-link { font-size: 10px;}
    .r-code { font-size: 11px; max-height: 60%;}

    .pca-opts { border-top: solid 1px black; margin-top: 5px}
    .pca-opts .pca-title { font-size: 10pt; font-weight: bold; margin-bottom: 3px; }

</style>

<template>
<div>
    <div v-if='load_failed' class="container">
      <div class="jumbotron">
        <h1>Degust</h1>
        <p><a :href='home_link'>Degust</a> failed to load your data :(</p>
        <p>Error</p>
        <div class='error-msg'></div>
      </div>
    </div>

  <div v-if='load_success'>
    <div class="navbar navbar-inverse navbar-static-top">
      <div class="container">
        <div class="navbar-header">
          <button type="button" class="navbar-toggle" data-toggle="collapse" data-target="#right-navbar-collapse">
            <span class="sr-only">Toggle navigation</span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </button>

          <a class="navbar-brand" :href="home_link">Degust : </a>
          <span class="navbar-brand exp-name"></span>
        </div>

        <ul class="nav navbar-nav navbar-right navbar-collapse collapse" id="right-navbar-collapse">
          <li><a class="log-link" href="#">Logs</a></li>
          <li><a id="tour" href="#">Tour</a></li>
          <li><a class="config" :href="config_url" v-show='can_configure'>Configure</a></li>
          <li class="dropdown">
            <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false">QC <span class="caret"></span></a>
            <ul class="dropdown-menu">
              <li><a href="#" class='p-value-histogram'>P-value histogram</a></li>
              <li><a href="#" class='bargraph-libsize'>Library size</a></li>
              <li><a href="#" class='expression-boxplot'>Expression box-whisker</a></li>
            </ul>
          </li>
          <li><a @click='show_about=true'>About</a></li>
        </ul>
      </div>
    </div>

    <div class='log-list'>
      <h4>Log messages</h4>
    </div>

    <div class='container'>
      <div class='right'>
        <ul class="nav nav-tabs">
          <li id='select-options'><a href="#">Options</a></li>
          <li id='select-single-gene-expr'><a href="#">Gene</a></li>
        </ul>

        <div class='single-gene-expr'>
        </div>

        <div class='filter options'>
          <h4>Options</h4>
          <div title='Filter genes by False Discovery Rate' data-placement='left'>
            <label>FDR cut-off</label>
            <slider-text class='slider-control'
                        v-model='fdrThreshold'
                        :step-values='[0, 1e-6, 1e-5, 1e-4, 0.001, .01, .02, .03, .04, .05, 0.1, 1]'
                        :validator="fdrValidator"
                        :dropdowns="[{label: '1', value: 1},{label: '0.05',value: 0.05},{label:'0.01',value:0.01},{label:'0.001',value:0.001},{label:'0.0001',value:0.0001}]"
                        :warning="fdrWarning"
                        >
            </slider-text>
          </div>

          <div title='Filter genes by absolute log fold change between any pair of samples' data-placement='left'>
            <label>abs logFC</label>
            <slider-text class='slider-control'
                        v-model='fcThreshold'
                        :step-values='fcStepValues'
                        :validator="intValidator"
                        :dropdowns="[{label: '0 (all)', value: 0},{label: '0.585 (> 1.5x)',value: 0.585},{label:'1 (> 2x)',value:1},{label:'2 (> 4x)',value:2},{label:'3 (> 8x)',value:3},{label:'4 (> 16x)',value:4}]"
                        :warning="fcWarning"
                        >
            </slider-text>
          </div>

          <div title='Show FC from selected condition' data-placement='left'>
            <label for='fc-relative'>FC relative to</label>
            <select id='fc-relative' v-model='fc_relative_i'>
                <option v-for='(col,i) in fc_columns' :value='i'>{{col.name}}</option>
                <option value='-1'>Average</option>
            </select>
          </div>
          <div title='FC for the MA-plot' data-placement='left'>
            <label for='ma-fc-col'>MA-Plot FC</label>
            <select id='ma-fc-col' v-model='ma_plot_fc_col_i'>
                <option v-for='(col,i) in fc_columns' :value='i'>{{col.name}}</option>
            </select>
          </div>
          <div title='Show raw counts (or counts-per-million) in the table' data-placement='left' class='show-counts-opt'>
            <label for='show-counts'>Show Counts</label>
            <select v-model="showCounts">
              <option value='no'>No</option>
              <option value='yes'>Yes</option>
              <option value='cpm'>As counts-per-million</option>
            </select>
          </div>
          <div class='pca-opts' v-show="cur_plot=='mds'">
            <div class='pca-title'>MDS options</div>
            <div title='Number of genes to use for the MDS plot' data-placement='left' class='pca-num-genes-opt'>
              <label>Num genes</label>
              <slider-text class='slider-control'
                          v-model='numGenesThreshold'
                          :step-values='fcStepValues'
                          :validator="intValidator"
                          ref='num_genes'
                          >
              </slider-text>
            </div>
            <div title='Number of genes to ignore for the MDS plot' data-placement='left' class='pca-skip-genes-opt'>
              <label>Skip genes</label>
              <slider-text class='slider-control'
                          v-model='skipGenesThreshold'
                          :validator="intValidator"
                          ref='skip_genes'
                          >
              </slider-text>
            </div>
            <div title='MDS dimensions to plot' data-placement='left' class='pca-dims-opt'>
              <label>Dimensions</label>
              <slider-text class='slider-control'
                          v-model='mdsDimension'
                          :step-values='[1,2,3,4,5,6,7,8,9,10]'
                          :validator="intValidator"
                          :fmt='fmtPCAText'
                          :text-disable='true'
                          >
              </slider-text>
            </div>
            <div title='MDS in 2d or 3d' data-placement='left' class='mds-2d3d-opt'>
              <label for='mds-2d3d'>MDS plot</label>
              <select v-model='mds_2d3d'>
                <option value='2d'>2d</option>
                <option value='3d'>3d</option>
              </select>
            </div>
          </div><!-- div.pca-opts -->
        </div>

        <div class='filter kegg-filter'>
          <h4>Kegg Pathway</h4>
          <select id='kegg'></select>
        </div>

        <div class='text-right'>
          <a class="genesets-toggle" role="button" data-toggle="collapse" href="#genesets" aria-expanded="false" aria-controls="genesets">
              Gene Sets
          </a>
        </div>
        <div class="collapse" id="genesets">
          <div class='filter'>
            <h4>Gene Sets</h4>
            <a class='btn btn-primary btn-xs geneset-save'>Save Current as Gene Set</a>
            <div class="geneset-search">
              <label>Search</label>
              <input type="text" class='search' />
            </div>
          </div>
        </div>

        <div class='text-right' v-show='settings.analyze_server_side'>
          <a class='sm-link' @click='show_r_code'>Show R code</a>
        </div>

        <div class='text-right'>
          <a class='sm-link' @click='update_url_link'>Update Link</a>
        </div>

        <div class='text-right'>
          <a class='sm-link' @click='show_heatmap=!show_heatmap'>
              <span v-if='show_heatmap'>Hide</span>
              <span v-else>Show</span>
              heatmap
          </a>
        </div>
      </div>

      <div class='row'>
        <conditions-selector v-show='settings.analyze_server_side'
                            :settings='settings'
                            :dge_method='dge_method' :sel_conditions='sel_conditions' @apply='change_samples'>
        </conditions-selector>

        <div class='col-xs-6' id='expression'>
          <div v-show='num_loading>0' class='loading'><img :src='asset_base + "images/ajax-loader.gif"'></div>
          <ul class="nav nav-tabs">
            <li :class='{active: cur_plot=="parallel-coord"}'>
                <a @click='cur_plot="parallel-coord"'>Parallel Coordinates</a>
            </li>
            <li :class='{active: cur_plot=="ma"}'>
                <a @click='cur_plot="ma"'>MA plot</a>
            </li>
            <li :class='{active: cur_plot=="mds"}'>
                <a @click='cur_plot="mds"'>MDS plot</a>
            </li>
            <li :class='{active: cur_plot=="volcano"}'>
                <a @click='cur_plot="volcano"'>Volcano</a>
            </li>
          </ul>
          <div v-bind:style="{ opacity: num_loading>0 ? 0.4 : 1 }">
              <ma-plot v-if='cur_plot=="ma"'
                       :data='gene_data_rows'
                       :filter='expr_filter'
                       :filter-changed='filter_changed'
                       :logfc-col='ma_plot_fc_col'
                       :avg-col='avg_column'
                       :fdr-col='fdr_column'
                       :colour='plot_colouring'
                       :info-cols='info_columns'
                       :highlight='genes_highlight'
                       @brush='set_genes_selected'
                       >
              </ma-plot>
              <volcano-plot v-if='cur_plot=="volcano"'
                       :data='gene_data_rows'
                       :filter='expr_filter'
                       :filter-changed='filter_changed'
                       :logfc-col='ma_plot_fc_col'
                       :avg-col='avg_column'
                       :fdr-col='fdr_column'
                       :colour='plot_colouring'
                       :info-cols='info_columns'
                       :highlight='genes_highlight'
                       @brush='set_genes_selected'
                       >
              </volcano-plot>
              <mds-plot v-if='cur_plot=="mds"'
                       :gene-data='gene_data'
                       :columns='count_columns'
                       :filter='expr_filter'
                       :filter-changed='filter_changed'
                       :condition-colouring='condition_colouring'
                       :num-genes='numGenesThreshold'
                       :skip-genes='skipGenesThreshold'
                       :dimension='mdsDimension'
                       @top-genes='set_genes_selected'
                       @dimension='v => mdsDimension = v'
                       >
              </mds-plot>
          </div>
        </div><!-- expression -->
      </div><!-- row -->

      <div class='row hide'>
          <div id="dge-pc" class="parcoords"></div>
          <div id="dge-ma" class="dge-ma"></div>
          <div id="dge-pca"></div>
          <div id="dge-volcano" class="dge-ma"></div>
      </div>

      <div class='row' v-if='show_heatmap'>
        <div id="heatmap-info"></div>
        <div id='heatmap'></div>
      </div>

      <div class='row'>
        <h2>Genes</h2>
        <gene-table :gene-data='gene_data' :link-url='settings.link_url'
                    :rows='genes_selected' :show-counts='showCounts'
                    @mouseover='genes_highlight=[$event]' @mouseout='genes_highlight=[]'
                    >
        </gene-table>
      </div>

    </div>

    <div id='kegg-image'></div>

    <!-- About box Modal -->
    <about :show='show_about' @close='show_about=false'></about>

    <!-- Error box Modal -->
    <div id='error-modal' class='modal fade' tabindex='-1' role='dialog' aria-labelledby='myModalLabel' aria-hidden='true'>
      <div class='modal-dialog'>
        <div class='modal-content'>
          <div class='modal-header'>
            <button type='button' class='close' data-dismiss='modal' aria-hidden='true'>x</button>
            <h3>Error</h3>
          </div>
          <div class='modal-body'>
            Error Message:
            <pre class='error-msg'></pre>
            Input:
            <pre class='error-input'></pre>
          </div>
          <div class='modal-footer'>
            <button class='btn btn-primary' data-dismiss='modal' aria-hidden='true'>Close</button>
          </div>
        </div><!-- /.modal-content -->
      </div><!-- /.modal-dialog -->
    </div><!-- /.modal -->

    <!-- Modal for showing R code -->
    <modal :showModal='r_code.length>0' :closeAction='close_r_code'>
        <h3 slot='header'>DGE R Code</h3>
        <div slot='body'>
            This is the R code the backend used to perform the DGE analysis for the current page.
            <pre class='r-code'>
                {{r_code}}
            </pre>
        </div>
        <div slot='footer'>
          <button class='btn btn-primary' @click='close_r_code'>Close</button>
        </div>
    </modal>

  </div>
</div>
</template>

<script lang='coffee' src="./compare.coffee"></script>
