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
    <edit-overlay class='col-xs-2' :enabled='editing' @cancel='cancel' @apply='apply'>
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
                    <select v-model='cur.dge_method' @click='editing=true' class='dge-method'>
                        <option v-for='method in dge_methods' :value='method[0]'>{{method[1]}}</option>
                    </select>
                </div>
            </div>
            <!-- <div class='col-xs-4'>
                <a class="weights-toggle" role="button" data-toggle="collapse" href=".weights" aria-expanded="false" aria-controls="genesets">
                    Sample weights
                </a>
                <div class='weights collapse'></div> -->
            <div class='col-xs-5' align="right">
                <a @click='showSampleWeights' v-if='cur.dge_method=="voom-weights"'>View sample weights</a>
            </div>
            </div>
            </div>
        </div>
    </edit-overlay>
</template>

<script lang='coffee'>

editOverlay = require('./edit-overlay.vue').default

module.exports =
    components:
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
        settings:
            required: true
    data: () ->
        cur:
            dge_method: this.dge_method
            sel_conditions: this.sel_conditions
            sel_contrast: this.sel_contrast
            sel_contrast_idx: null
        editing: false
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
        'cur.sel_contrast_idx': () ->
            this.update_sel_contrast()
    computed:
        conditions: () ->
            this.settings.replicates.map((c) -> {name:c[0]}).filter((c) => !(c.name in this.hidden_factors))
        hidden_factors: () ->
            this.settings.hidden_factor
        contrasts: () ->
            this.settings.contrasts || []
    methods:
        update_sel_contrast_idx: () ->
            this.cur.sel_contrast_idx = this.contrasts.findIndex((x) => x==this.cur.sel_contrast)
        update_sel_contrast: () ->
            idx = this.cur.sel_contrast_idx
            if ((idx>=0) && (idx < this.contrasts.length))
                this.cur.sel_contrast = this.contrasts[idx]
            else
                this.cur.sel_contrast = null

        click_condition: () ->
            this.editing=true
            this.cur.sel_contrast_idx=null
        click_contrast: (x) ->
            this.editing=true
            this.cur.sel_conditions=[]
        apply: () ->
            this.editing=false
            this.$emit('apply', this.cur)
        cancel: () ->
            this.editing=false
            this.cur.dge_method = this.dge_method
            this.cur.sel_conditions = this.sel_conditions
            this.cur.sel_contrast = this.sel_contrast
            this.update_sel_contrast_idx()
        showSampleWeights: () ->
            this.$emit('SampleWeights')


</script>
