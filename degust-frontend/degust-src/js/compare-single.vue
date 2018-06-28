<style scoped>
    #expression { position: relative; }
    .loading { position: absolute; top: 100px; left: 250px; }

    .slider-control { display: inline-block; }
    a.sm-link { font-size: 10px;}
    .r-code { font-size: 11px; max-height: 60%;}

    .pca-opts { border-top: solid 1px black; margin-top: 5px}
    .pca-opts .pca-title { font-size: 10pt; font-weight: bold; margin-bottom: 3px; }

    .heatmap-info { font-size: 9pt; height: 2em; }
    .heatmap-info .lbl { margin-left: 20px; font-weight: bold; display: inline-block;}

    #descPreformatted {
      margin: 1em 0;
      display: block;
      font-size: 9pt;
    }

    #experimentDescriptionLoc {
      font-size: 7.5pt;
    }

    #descTooltip {
      position: absolute;
      text-align: left;
      padding: 6px 12px 6px;
      font: 12px sans-serif;
      background: #fff;
      color: #000000;
      border: 1px;
      border-radius: 6px;
      border-color: #000000;
      border-style: solid;
      pointer-events: none;
      width: 'auto';
      opacity: 1;
      margin: 0 auto;
      -webkit-transform: translate(50%, -90%);
    }

    #descTooltip::after {
    content: " ";
    position: absolute;
    top: 50%;
    right: 100%; /* To the left of the tooltip */
    margin-top: -5px;
    border-width: 5px;
    border-style: solid;
    border-color: transparent black transparent transparent;
    }



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
    </div> <!-- load_failed -->

    <navbar v-if='navbar'
            :homeLink='home_link'
            :experimentName='experimentName'
            :fullSettings='full_settings'
            :extraMenuHtml='full_settings'
            :uniqueCode='code'
            @showAbout='v => show_about = v'
            >
            <li slot="qclist" class="dropdown" v-if='!is_pre_analysed'>
                <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false">
                QC <span class="caret"></span>
                </a>
                <ul class="dropdown-menu">
                <li v-for="plot of qc_plots"><a @click='show_qc=plot[0]'>{{ plot[1] }}</a></li>
                </ul>
            </li>
            <li slot="switchURL"><a class="config" :href="config_url">Configure</a></li>
    </navbar>
  <div class="container">
    <!-- About box Modal -->
    <about :show='show_about' @close='show_about=false'></about>

    <div v-if='load_success'>
      <div class='row'>
        <div class='col-xs-3'>
          <div class='row'> <!-- Give Condition Selector its own row-->
            <conditions-selector v-show='!is_pre_analysed' style='width:100%;'
                              :settings='settings'
                              :dge_method='dge_method'
                              :sel_conditions='sel_conditions'
                              :sel_contrast='sel_contrast'
                              :dge_methods='dge_methods'
                              @apply='change_samples'
                              @SampleWeights='show_extraInfo=true'>
            </conditions-selector>
          </div>
          <hr/>
          <div>
            <div class='filter options'>
              <div>
                  <h4>Options</h4>
              </div>
              <div v-tooltip="tip('Filter genes by False Discovery Rate')">
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

              <div v-tooltip="tip('Filter genes by absolute log fold change between any pair of samples')">
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

              <div v-tooltip="tip('Filter page to genes in this list')">
                <label>Gene list</label>
                <a @click='showGeneList=true'>{{(filter_gene_list.length == 0) ? "Create Filter" : "List Size: " + filter_gene_list.length }}</a>
              </div>

              <div v-tooltip="tip('Show FC from selected condition')">
                <label for='fc-relative'>FC relative to</label>
                <select id='fc-relative' v-model='fc_relative_i'>
                    <option v-for='(col,i) in fc_columns' :value='i'>{{col.name}}</option>
                    <option value='-1'>Average</option>
                </select>
              </div>
              <div v-tooltip="tip('FC for the MA-plot')" v-if='cur_plot=="ma" || cur_plot=="volcano"'>
                <label for='ma-fc-col'>Plot FC</label>
                <select id='ma-fc-col' v-model='ma_plot_fc_col_i'>
                    <option v-for='(col,i) in fc_calc_columns' :value='i'>{{col.name}}</option>
                </select>
              </div>
              <div class='pca-opts' v-show="cur_plot=='mds'">
                <div class='pca-title'>MDS options</div>
                <div v-if='!is_maxquant' v-tooltip="tip('Normalization of gene expression used to calculated MDS and Heatmap')">
                  <label>Normalized</label>
                  <select v-model='normalization'>
                    <option value='cpm'>CPM</option>
                    <option value='backend'>Backend normalization</option>
                    <option v-if='settings.hidden_factor.length>0' value='remove-hidden'>Remove hidden factors</option>
                  </select>
                </div>
                <div v-if='normalization=="cpm"'
                    v-tooltip="tip('Moderation in CPM to add to each gene, for calculating MDS and heatmap')">
                  <label>Moderation</label>
                  <slider-text class='slider-control'
                              v-model='normalizationModeration'
                              :step-values='[0.5,1,2,3,4,5,6,7,8,9,10]'
                              :validator="moderationValidator"
                              >
                  </slider-text>
                </div>
                <div v-tooltip="tip('Number of genes to use for the MDS plot')" class='pca-num-genes-opt'>
                  <label>Num genes</label>
                  <slider-text class='slider-control'
                              v-model='numGenesThreshold'
                              :validator="intValidator"
                              ref='num_genes'
                              >
                  </slider-text>
                </div>
                <div v-tooltip="tip('Number of genes to ignore for the MDS plot')" class='pca-skip-genes-opt'>
                  <label>Skip genes</label>
                  <slider-text class='slider-control'
                              v-model='skipGenesThreshold'
                              :validator="intValidator"
                              ref='skip_genes'
                              >
                  </slider-text>
                </div>
                <div v-tooltip="tip('MDS dimensions to plot')" class='pca-dims-opt'>
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
                <div v-tooltip="tip('Plot the MDS dimensions to the same scale, or independently')">
                  <label>Dim scale</label>
                  <select v-model='mdsDimensionScale'>
                    <option value='independent'>independent</option>
                    <option value='common'>common</option>
                  </select>
                </div>

                <div v-tooltip="tip('MDS in 2d or 3d')">
                  <label>MDS plot</label>
                  <select v-model='mds_2d3d'>
                    <option value='2d'>2d</option>
                    <option value='3d'>3d</option>
                  </select>
                </div>
              </div><!-- div.pca-opts -->
            </div>

            <div class='text-left' v-show='!is_pre_analysed'>
              <a class='sm-link' @click='show_r_code'>Show R code</a>
            </div>
            <div class='text-left' v-if='!show_heatmap'>
              <a class='sm-link' @click='show_heatmap=true'>
                  Show heatmap
              </a>
            </div>
            <div class='text-left'>
                    <a  @mouseover='hoverDesc'
                        @mouseout="show_hoverDesc=false"
                        @mouseup='clickDesc'
                        id="experimentDescriptionLoc"
                        >Show Description
                    </a>
                <div class='tooltip' v-if='show_hoverDesc' :style='tooltipStyleDesc' ref='tooltip' id='descTooltip'>
                  <pre id='descPreformatted'>{{ settings.experimentDescription }}</pre>
                </div>
            </div>
          </div>
        </div>

        <div class='col-xs-9'>
          <div class='col-xs-9' id='expression'>
            <div v-show='num_loading>0' class='loading'><img :src='$global.asset_base + "images/ajax-loader.gif"'></div>
            <ul class="nav nav-tabs">
              <li :class='{active: cur_plot=="parcoords"}'>
                  <a @click='cur_plot="parcoords"'>Parallel Coordinates</a>
              </li>
              <li :class='{active: cur_plot=="ma"}'>
                  <a @click='cur_plot="ma"'>MA plot</a>
              </li>
              <li :class='{active: cur_plot=="mds"}' v-if='!is_pre_analysed'>
                  <a @click='cur_plot="mds"'>MDS plot</a>
              </li>
              <li :class='{active: cur_plot=="volcano"}'>
                  <a @click='cur_plot="volcano"'>Volcano</a>
              </li>
            </ul>
            <div v-bind:style="{ opacity: num_loading>0 ? 0.4 : 1 }">
                <parallel-coord v-if='cur_plot=="parcoords"'
                        :data='gene_data_rows'
                        :dimensions='fc_calc_columns'
                        :filter='expr_filter'
                        :filter-changed='filter_changed'
                        :colour='plot_colouring'
                        :highlight='genes_highlight'
                        @brush='set_genes_selected'
                        >
                </parallel-coord>
                <ma-plot v-if='cur_plot=="ma"'
                        :name='experimentName+" - "+"ma-plot"'
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
                        @hover-start='v => genes_hover=v'
                        >
                </ma-plot>
                <volcano-plot v-if='cur_plot=="volcano"'
                        :name='experimentName+" - "+"volcano"'
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
                        @hover-start='v => genes_hover=v'
                        >
                </volcano-plot>
                <mds-plot v-if='cur_plot=="mds"'
                        :name='experimentName+" - "+"mds"'
                        :data='gene_data_rows'
                        :filter='expr_filter'
                        :filter-changed='filter_changed'
                        :columns='normalizationColumns'
                        :numGenes='numGenesThreshold'
                        :skipGenes='skipGenesThreshold'
                        :condition-colouring='condition_colouring'
                        :dimension='mdsDimension'
                        :dimensionScale='mdsDimensionScale'
                        :plot2d3d='mds_2d3d'
                        @top-genes='set_genes_selected'
                        @dimension='v => mdsDimension = v'
                        >
                </mds-plot>
              </div>
            </div><!-- expression -->

            <div class='col-xs-3'>
              <gene-stripchart v-if='!is_pre_analysed'
                              :gene-data='gene_data'
                              :colour='condition_colouring'
                              :useIntensity='is_maxquant'
                              :selected='genes_hover'
                              >
              </gene-stripchart>

            </div>
            <div class='row' v-if='show_heatmap'> <!-- Heatmap -->
              <heatmap :gene-data='gene_data'
                      :genes-show='genes_selected'
                      :dimensions='heatmap_dimensions'
                      :highlight='genes_hover'
                      :show-replicates='heatmap_show_replicates'
                      :info-cols='info_columns'
                      :logfCcol='ma_plot_fc_col'
                      :avgCol='avg_column'
                      :fdrCol='fdr_column'
                      @hide='show_heatmap=false'
                      @show-replicates='v => heatmap_show_replicates=v'
                      @mousehover='hover_heatmap' @hover-end='stop_hover_heatmap'
                      @hover-start='v => genes_hover=v'
                      >
              </heatmap>
            </div>
          </div> <!-- col-xs-9 -->
        </div><!-- row -->

      <div class='row'>
        <h2>Genes</h2>
        <gene-table :name='experimentName'
                    :gene-data='gene_data' :link-url='settings.link_url'
                    :fc-columns='fc_calc_columns'
                    :rows='genes_selected' :show-counts='showCounts' :show-intensity='showIntensity'
                    :useProt='is_maxquant'
                    @mouseover='gene_table_hover' @mouseout='gene_table_nohover'
                    :allCols='all_columns'
                    :allowSelcols='true'
                    @showSelectColumns='show_selectCols=true'
                    >
        </gene-table>
      </div> <!-- row -->

    </div> <!-- load_success -->

    <!-- Gene List box Modal -->
    <filterGenes :show='showGeneList' @close='showGeneList=false' @filterList='filterList'></filterGenes>

    <clickExpDesc
              :show='show_clickDesc'
              :desc='settings.experimentDescription'
              @close='show_clickDesc=false'>
    </clickExpDesc>

    <extraInfo
              :show='show_extraInfo'
              :extraInfoData='extraInfo_data'
              @close='show_extraInfo=false'>
    </extraInfo>

    <qc-plots
              :show-qc='show_qc'
              :gene-data='gene_data'
              :colour='condition_colouring'
              @close='show_qc=""'>
    </qc-plots>

    <ErrorMsg
                  :show='show_Error'
                  :errorMsg='error_msg'
                  @close='show_Error=false'
    >
    </ErrorMsg>

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

<script lang='coffee' src="./compare-single.coffee"></script>
