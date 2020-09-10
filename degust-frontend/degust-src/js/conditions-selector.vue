<style scoped>

.files { border: 1px solid #aaa; border-radius: 5px; background-color: #eee; padding: 3px 8px; margin-top: 10px; max-height: 130px; overflow-y: scroll;}
.files label { display: block; font-weight: normal; }

.hidden-factors {
    border: 1px solid #aaa;
    border-radius: 5px;
    background-color: #eee;
    padding: 3px 8px;
    margin-top: 10px;
    opacity: 0.8;
}
.hidden-factors h4 {font-size: 12px;}
.hidden-factors label {font-size: 10px;}
.hidden-factors td {
    font-size: 12px;
    border: 1px solid #aaa;
    text-align: right;
    padding: 1px;
}

a {font-size: 10px}

.dge-method {font-size: 12px; }

.dge-filters { margin-top: 5px; }
.dge-filters >>> label, .dge-filters >>> input { display: inline-block; font-size: 8pt; }
.dge-filters >>> label { width: 120px; text-align: right;}
.dge-filters >>> select { display: inline-block; font-size: 8pt; max-width: 200px; }
.dge-filters >>> input { width: 50px; }
.slider-control { display: inline-block; }

::-webkit-scrollbar {
  -webkit-appearance: none;
  width: 7px;
}
::-webkit-scrollbar-thumb {
  border-radius: 4px;
  background-color: rgba(0, 0, 0, .5);
  -webkit-box-shadow: 0 0 1px rgba(255, 255, 255, .5);
}
</style>

<template>
    <edit-overlay class='col-xs-2' :enabled='editing' :valid='isValid' :need-update='overlayUpdate' @cancel='cancel' @apply='apply'>
        <div class='conditions'>
            <h4>Conditions</h4>
            <div class='files'>
                <label v-for='c in conditions'>
                    <input type='checkbox'
                           v-model='cur.sel_conditions'
                           :value='c.name'
                           @click='click_condition()'>
                           {{c.name}}
                </label>
                <div v-if='contrasts.length>0'>
                    <b>Contrasts</b>
                    <label v-for='(c,idx) in contrasts'>
                        <input type='radio'
                               v-model='cur.sel_contrast_idx'
                               :value='idx'
                               @click='click_contrast(idx)'>
                               {{c.name}}
                    </label>
                </div>
            </div>
            <div v-show='hidden_factors.length>0' class='hidden-factors'>
                <h4>Hidden Factors</h4>
                <div v-for='name in hidden_factors'><label>{{name}}</label></div>
            </div>
            <div v-if='cur.sel_contrast' class='hidden-factors'>
                <h4>Contrast</h4>
                <table>
                    <tr v-for='(val,idx) in cur.sel_contrast.column'>
                        <td>{{settings.replicates[idx][0]}}:</td>
                        <td>{{val}}</td>
                    </tr>
                </table>
            </div>
            <div class='row'>
                <div class='col-xs-7'>
                    <div v-show='dge_methods.length>0'>
                        <label>Method</label>
                        <select v-model='cur.dge_method' @mousedown='editing=true' class='dge-method'>
                            <option v-for='method in dge_methods_grp.bare' :value='method[0]'>{{method[1]}}</option>
                            <optgroup v-for='grp in dge_methods_grp.grps' :label='grp.label'>
                                <option v-for='method in grp.list' :value='method[0]'>{{method[1]}}</option>
                            </optgroup>
                        </select>
                    </div>
                </div>
            </div>

            <div class='row dge-filters' v-if='cur.dge_method=="voom-topconfects"'>
              <div class='col-xs-12'>
                <label>FDR cut-off</label>
                <slider-text class='slider-control'
                            :value_in='cur.dge_parameters.confect_fdr' @input='fdrChanged'
                            :step-values='[0, 1e-6, 1e-5, 1e-4, 0.001, .01, .02, .03, .04, .05, 0.1, 0.5]'
                            :dropdowns="[{label: '1', value: 1},{label: '0.05',value: 0.05},{label:'0.01',value:0.01},{label:'0.001',value:0.001},{label:'0.0001',value:0.0001}]"
                            >
                </slider-text>
              </div>
            </div> <!-- topconfect options -->

            <div v-if='cur.dge_method=="RUV-edgeR"'>
                <small><b>Experimental feature! Using <a target=_blank href='https://bioconductor.org/packages/release/bioc/html/RUVSeq.html'>RUVSeq</a></b></small>
                <div class='row dge-filters'>
                  <div class='col-xs-12'>
                    <label>Normalization</label>
                    <select v-model='cur.dge_parameters.ruv.normalization' @mousedown='editing=true'
                            v-tooltip='tip("Normalization to use with RUV")'>
                        <option value='TMM'>TMM</option>
                        <option value='none'>none</option>
                        <option value='upperquartile'>upper-quartile</option>
                        <option value='RLE'>relative log expression</option>
                    </select>
                  </div>
                </div>
                <div class='row dge-filters'>
                  <div class='col-xs-12'>
                    <label>Flavour</label>
                    <select v-model='cur.dge_parameters.ruv.flavour' @mousedown='editing=true'
                            v-tooltip='tip("Use RUVg or RUVr from the RUVSeq package")'>
                        <option value='ruvg'>RUVg</option>
                        <option value='ruvr'>RUVr</option>
                    </select>
                  </div>
                </div>
                <div class='row dge-filters'>
                  <div class='col-xs-12'>
                    <label>k</label>
                    <input type="text" width=3 v-model='cur.dge_parameters.ruv.k' @mousedown='editing=true'
                           v-tooltip='tip("Number of dimensions of unwanted variation to remove")' />
                  </div>
                </div>
                <div class='row dge-filters' v-if='cur.dge_parameters.ruv.flavour=="ruvg"'>
                  <div class='col-xs-12'>
                    <label>Proportion empirical</label>
                    <input type="text" width=3 v-model='cur.dge_parameters.ruv.prop_empirical' @mousedown='editing=true'
                           v-tooltip='tip("Proportion of genes to use as empirical negative-control genes.")' />
                  </div>
                </div>
            </div> <!-- RUV options -->

        </div>
    </edit-overlay>
</template>

<script lang='coffee'>

editOverlay = require('./edit-overlay.vue').default
sliderText = require('./slider.vue').default

module.exports =
    components:
        sliderText: sliderText
        editOverlay: editOverlay
    props:
        dge_methods:
            required: true
        dge_method:
            required: true
        sel_conditions:
            required: true
        sel_contrast:
            required: true
        dge_parameters:
            required: true
        settings:
            required: true
    data: () ->
        cur:
            dge_method: this.dge_method
            sel_conditions: this.sel_conditions
            sel_contrast: this.sel_contrast
            sel_contrast_idx: null
            dge_parameters:
                confect_fdr: 0.05
                ruv:
                    flavour: 'ruvg'
                    k: 1
                    prop_empirical: 0.5
                    normalization: 'TMM'
        editing: false
        overlayUpdate: 0
    watch:
        dge_method: (v) ->
            this.cur.dge_method=v
            this.editing = false
        sel_conditions: (v,o) ->
            this.cur.sel_conditions=v
            this.editing = false
        sel_contrast: (v,o) ->
            this.cur.sel_contrast=v
            this.update_sel_contrast_idx()
            this.editing = false
        dge_parameters: () ->
            deep: true,
            handler: (v) ->
                this.cur.dge_parameters = JSON.parse(JSON.stringify(v))  # Deep obj copy
                this.editing=false
        'cur.sel_contrast_idx': () ->
            this.update_sel_contrast()
        'cur.dge_method': () ->
            this.overlayUpdate+=1
    computed:
        conditions: () ->
            this.settings.replicates.map((c) -> {name:c[0]}).filter((c) => !(c.name in this.hidden_factors))
        hidden_factors: () ->
            this.settings.hidden_factor
        contrasts: () ->
            this.settings.contrasts || []
        isValid: () ->
            if this.cur.sel_contrast?
                return this.cur.dge_method!='voom-topconfects'
            if this.cur.sel_conditions.length>2
                return this.cur.dge_method!='voom-topconfects'
            return this.cur.sel_conditions.length>1
        dge_methods_grp: () ->
            bare = []
            grps = []
            by_key = {}
            for m in this.dge_methods
                if m.length==2
                    bare.push(m)
                else
                    k = m[2]
                    if (!(k of by_key))
                        by_key[k] = {label: k, list:[]}
                        grps.push(by_key[k])
                    by_key[k].list.push(m)
            {bare: bare, grps: grps}
    methods:
        tip: (txt) ->
            {content:txt, placement:'right'}

        fdrChanged: (v) ->
            if v != this.dge_parameters.confect_fdr
                this.editing=true
            this.cur.dge_parameters.confect_fdr = v
        update_sel_contrast_idx: () ->
            this.cur.sel_contrast_idx = this.contrasts.findIndex((x) => x==this.cur.sel_contrast)
        update_sel_contrast: () ->
            this.overlayUpdate+=1
            idx = this.cur.sel_contrast_idx
            if ((idx>=0) && (idx < this.contrasts.length))
                this.cur.sel_contrast = this.contrasts[idx]
            else
                this.cur.sel_contrast = null
        click_condition: () ->
            this.editing=true
            this.cur.sel_contrast_idx=null
            this.overlayUpdate+=1
        click_contrast: (x) ->
            this.editing=true
            this.cur.sel_conditions=[]
            this.overlayUpdate+=1
        apply: () ->
            this.editing=false
            this.$emit('apply', this.cur)
        cancel: () ->
            this.cur.dge_method = this.dge_method
            this.cur.sel_conditions = this.sel_conditions
            this.cur.sel_contrast = this.sel_contrast
            this.cur.dge_parameters = JSON.parse(JSON.stringify(this.dge_parameters))  # Deep obj copy
            this.update_sel_contrast_idx()
            this.editing=false

</script>
