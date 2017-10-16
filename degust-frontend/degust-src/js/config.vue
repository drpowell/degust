<style src="../../node_modules/vue-multiselect/dist/vue-multiselect.min.css"></style>
<style>
    .options { border: 1px solid #aaa; border-radius: 5px; background-color: #eee; padding: 10px 3px; }

    .conditions { border: 1px solid #aaa; border-radius: 5px; padding: 0 3px; }

    .view { float: right; }
    .del-condition { float: right; }

    .init-select, .hidden-factor {margin-left: 15px; font-size: smaller;}
    .condition-up-down {display: inline-block; position: absolute;; width: 15px; height: 15px}
    .condition-up-down .glyphicon-triangle-top {position: absolute; top: 4px;}
    .condition-up-down .glyphicon-triangle-bottom {position: absolute; top: 20px;}
    .disabled {opacity: 0.5;}

    .col-name {width: 100%; margin-left: 16px; padding: 7px 0;}

    /* Hack to improve layout of multiselect */
    .conditions .multiselect__single {display: none;}

    .multiselect__option {padding: 5px; font-size: 12px; min-height: auto;}
    .multiselect__content-wrapper { border: thin solid black;}

    .rep_used { padding: 0 3px; background-color: #ddd; border-radius: 3px; margin-left: 10px; float: right;}

    .fade-enter-active, .fade-leave-active { transition: opacity .5s }
    .fade-enter, .fade-leave-to  { opacity: 0  }

    #grid { height: 300px; font-size: 8pt; }

    #grid >>> .slick-row { font-size: 8pt; }
    #grid >>> .slick-row:hover {
      font-weight: bold;
      color: #069;
    }
</style>


<template>
    <div>

        <div class="navbar navbar-inverse navbar-static-top">
          <div class="container">
            <div class="navbar-header">
              <a class="navbar-brand" href="/">Degust : </a>
              <span class="navbar-brand exp-name">{{settings.name}}</span>
            </div>
            <ul class="nav navbar-nav navbar-right navbar-collapse collapse" id="right-navbar-collapse">
              <li><a class="log-link" href="#">Logs</a></li>
              <li><a class="view" v-bind:href="view_url">View</a></li>
              <li><a @click='show_about=true'>About</a></li>
            </ul>
          </div>
        </div>


        <div class='log-list'>
          <h4>Log messages</h4>
        </div>

        <div class="container">
          <h1>Configuration</h1>

          <div class="row">
            <div class="col-md-12 options">
              <form class="form-horizontal">

              <div class="form-group">
                <label class="control-label col-sm-3" for="name">Name</label>
                <div class="controls col-sm-4">
                  <input v-model.trim='settings.name' class="form-control" type="text" name="name" placeholder="Unnamed" title="Optional: Give your experiment a name" data-placement='right' size='30' />
                </div>
              </div>

              <div class="form-group">
                <label class="control-label col-sm-3">Format type</label>
                <div class="controls col-sm-6">
                  <label class="radio">
                    <input v-model='settings.csv_format' v-bind:value=true type="radio">Comma separated (CSV)
                  </label>
                  <label class="radio">
                    <input v-model='settings.csv_format' v-bind:value=false type="radio">TAB separated (TSV)
                  </label>
                </div>
              </div>

              <div class="form-group">
                <label class="control-label col-sm-3">Info columns</label>
                <div class="controls col-sm-6">
                  <multiselect v-model="settings.info_columns" :options="columns_info" :multiple="true" :close-on-select="false" :show-labels="false" :searchable="true" placeholder="Add column"/>
                </div>
              </div>

              <div class="form-group">
                <label class="control-label col-sm-3" for="analyze-server-side">Analyze server side</label>
                <div class="controls col-sm-1">
                  <input v-model='settings.analyze_server_side'  class="form-control" type="checkbox" />
                </div>
              </div>

              <div v-show='settings.analyze_server_side'>
                <div class="form-group">
                  <label class="control-label col-sm-3" for="name">Min gene read count</label>
                  <div class="controls col-sm-1">
                    <input v-model.number='settings.min_counts' class="form-control" type="text" name="min-counts" placeholder="0" title="Optional: Minimum read count required in at least one replicate or the gene is ignored" data-placement='right' />
                  </div>
                </div>
                <div class="form-group">
                  <label class="control-label col-sm-3" for="name">Min gene CPM</label>
                  <div class="controls col-sm-1">
                    <input v-model.number='settings.min_cpm' class="form-control" type="text" name="min-cpm" placeholder="0" title="Optional: A gene must have at a CPM of at least this, in at least the number of specified samples" data-placement='right' />
                  </div>
                  <label class="control-label col-sm-2" for="name">in at least samples</label>
                  <div class="controls col-sm-1">
                    <input v-model.number='settings.min_cpm_samples' class="form-control" type="text" name="min-cpm" placeholder="0" title="Optional: A gene must have at a CPM of at least this, in at least the number of specified samples" data-placement='right' />
                  </div>
                </div>

                <div class="form-group">
                  <label class="control-label col-sm-3" for="config-locked">Config locked</label>
                  <div class="controls col-sm-1">
                    <input v-model='settings.config_locked' v-bind:disabled="!can_lock" class="form-control" type="checkbox" title="Lock the configuration page so only you can change it (you must be logged in)" data-placement='right' />
                  </div>
                </div>

                <div class="condition-group conditions">
                  <div class="form-group">
                    <span class="control-label col-sm-3">Condition name</span>
                    <span class="control-label col-sm-1">Replicates</span>
                  </div>

                  <div>
                      <div v-for='(rep,idx) in settings.replicates' class="form-group condition">
                        <div class="controls col-sm-3">
                            <div class='condition-up-down'>
                                <span @click='move_replicate(idx,-1)' :class='{disabled: idx==0}'

                                      class='glyphicon glyphicon-triangle-top'></span>
                                <span @click='move_replicate(idx,1)' :class='{disabled: idx+1==settings.replicates.length}'
                                      class='glyphicon glyphicon-triangle-bottom'></span>
                            </div>
                          <input v-model='rep.name' class="control-label col-name" placeholder="Condition Name"/>
                        </div>
                        <div class="col-sm-9">
                          <div class="col-sm-8">
                            <multiselect v-model="rep.cols" :options="columns_info"
                                         @input='selected_reps(rep)'
                                         :multiple="true" :close-on-select="false"
                                         :show-labels="false" :searchable="false"
                                         placeholder="Pick some">
                              <template slot="option" scope="props">
                                <div>{{props.option}}
                                    <span class='rep_used' v-for='cond in conditions_for_rep(props.option)'>{{cond}}</span>
                                </div>
                              </template>
                            </multiselect>
                          </div>
                          <div class="col-sm-4">
                              <label class='init-select'>
                                  <input v-model='rep.init' type="checkbox" />Initial select
                              </label>
                              <label class='hidden-factor'>
                                  <input v-model='rep.factor' type="checkbox" />Hidden Factor
                              </label>
                              <button v-on:click='del_replicate(idx)' type="button" class="del-condition">&times;</button>
                          </div>
                        </div>
                      </div>
                  </div>
                </div> <!-- conditions -->

                <div class="form-group">
                  <div class="col-sm-3">
                    <button v-on:click='add_replicate()' type="button" class="btn btn-primary" title="Add a new condition or treatment" data-placement='right'>Add condition</button>
                  </div>
                </div>
              </div>

              <div v-show='!settings.analyze_server_side'>
                <div class="form-group">
                  <label class="control-label col-sm-3" for="primary">Primary condition</label>
                  <div class="controls col-sm-3">
                    <input v-model='settings.primary_name' class="form-control" type="text" name="primary" placeholder="Primary" title="Name of the condition your fold-change data is relative to" data-placement='right' />
                  </div>
                </div>
                <div class="form-group">
                  <label class="control-label col-sm-3">FDR column</label>
                  <div class="controls col-sm-3">
                    <multiselect v-model="settings.fdr_column" :options="columns_info" :allow-empty="true" :searchable="false" :close-on-select="true" :show-labels="false" placeholder="--- Required ---" title="Column containing the False-Discovery-Rate.  Sometimes called 'adj.P.Val'" data-placement='right'></multiselect>
                    <span class='text-error'></span>
                  </div>
                </div>
                <div class="form-group">
                  <label class="control-label col-sm-3">Average expression column</label>
                  <div class="controls col-sm-3">
                    <multiselect v-model="settings.avg_column" :options="columns_info" :allow-empty="true" :searchable="false" :close-on-select="true" :show-labels="false" placeholder="--- Required ---" title="Column containing the average (log) expression information.  Often called 'Amean' or 'AveExpr'" data-placement='right'></multiselect>
                    <span class='text-error'></span>
                  </div>
                </div>
                <div class="form-group">
                  <label class="control-label col-sm-3">Fold-change columns</label>
                  <div class="controls col-sm-3">
                    <multiselect v-model="settings.fc_columns" :options="columns_info" :multiple="true" :close-on-select="false" :show-labels="false" :searchable="false" placeholder="Pick some" title="Columns containing the log fold-change data" data-placement='right'/>
                  </div>
                </div>
              </div>

              <button type='button' @click='advanced=!advanced'
                      class='btn btn-default btn-sm pull-right' style='margin-top:-45px;'>
                  Extra settings
              </button>
              <transition name="fade">
                  <div v-show='advanced'>
                      <div class="form-group">
                        <label class="control-label col-sm-3">EC Number column</label>
                        <div class="controls col-sm-3">
                          <multiselect v-model="settings.ec_column" :options="columns_info" :allow-empty="true" :searchable="false" :close-on-select="true" :show-labels="false" placeholder="--- Optional ---"></multiselect>
                        </div>
                      </div>
                      <div class="form-group">
                        <label class="control-label col-sm-3">Gene link column</label>
                        <div class="controls col-sm-3">
                          <multiselect v-model="settings.link_column" :options="columns_info" :allow-empty="true" :searchable="false" :close-on-select="true" :show-labels="false" placeholder="--- Optional ---"></multiselect>
                        </div>
                      </div>
                      <div class="form-group">
                        <label class="control-label col-sm-3">Gene link URL</label>
                        <div class="controls col-sm-3">
                          <input v-model='settings.link_url' class="form-control" type="text" size='50' placeholder="Leave blank to have Degust guess" title="Optional: External link for genes.  Any '%s' in the link will be replaced by the defined link column" data-placement='right' />
                        </div>
                      </div>

                      <div v-if='settings.analyze_server_side'>
                          <div class="form-group">
                            <label class="control-label col-sm-3">Default analysis</label>
                            <div class="controls col-sm-3">
                                <multiselect v-model="settings.dge_method" :options="dge_methods" track-by='value' label='label' :allow-empty="true" :searchable="false" :close-on-select="true" :show-labels="false" placeholder="--- Optional ---"></multiselect>
                                </select>
                            </div>
                          </div>
                          <div class="form-group">
                            <label class="control-label col-sm-3">Default FDR</label>
                            <div class="controls col-sm-3">
                                <input v-model.number='settings.fdrThreshold' class="form-control" type="text" placeholder="1" title="Optional: Default FDR threshold for display" data-placement='right' />
                            </div>
                          </div>
                      </div>
                  </div>
              </transition>

              <div class="form-group">
                <div class="col-sm-12">
                  <button v-on:click.prevent='save()' type="submit" class="btn btn-success">Save changes</button>
                  <button v-on:click.prevent='revert() 'type="button" class="btn btn-default">Revert</button>
                  <a v-bind:href="view_url" class="btn btn-default" title="View main page.  Note unsaved configuration will be lost" data-placement='right'>View</a>
                </div>
              </div>
            </form>
            </div> <!-- options -->
          </div> <!-- row -->

          <div class="row">Number of columns = {{columns_info.length}}</div>
          <slick-table id='grid'
                       :rows='asRows'
                       :columns='table_columns'
                       >
          </slick-table>
        </div> <!-- container -->

        <modal :showModal="modal.show" :closeAction="closeModal">
          <h1 slot="header">Saving settings</h1>
          <div slot="body">
              <div v-for='msg in modal.msgs' :class='modal.msgs_class'>
                  {{msg}}
              </div>
          </div>
          <div slot="footer">
            <button @click='closeModal' class="btn btn-primary">Close</button>
            <a v-if="modal.view" v-bind:href="view_url" class="view btn btn-default">View</a>
          </div>
        </modal>

        <!-- About box Modal -->
        <about :show='show_about' @close='show_about=false'></about>
    </div>
</template>
<script lang='coffee' src="./config.coffee"></script>
