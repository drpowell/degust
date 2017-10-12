<style scoped>

.files { border: 1px solid #aaa; border-radius: 5px; background-color: #eee; padding: 3px 8px; margin-top: 10px}
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

.dge-method {font-size: 12px;}

</style>

<template>
    <edit-overlay class='col-xs-2' :enabled='editing' @cancel='cancel' @apply='apply'>
        <div class='conditions'>
          <h3>Conditions</h3>
          <div class='files'>
              <label v-for='c in conditions'>
                  <input type='checkbox' v-model='cur.sel_conditions' :value='c.name' @click='editing=true'> {{c.name}}
             </label>
          </div>
          <div v-show='hidden_factors.length>0' class='hidden-factors'>
              <h4>Hidden Factors</h4>
              <div v-for='name in hidden_factors'><label>{{name}}</label></div>
          </div>
          <label>Method</label>
          <select v-model='cur.dge_method' @click='editing=true' class='dge-method'>
            <option value='voom'>Voom/Limma</option>
            <option value='edgeR-quasi'>edgeR quasi-likelihood</option>
            <option value='edgeR'>edgeR</option>
            <option value='voom-weights'>Voom (samp weights)</option>
          </select>
          <a class="weights-toggle" role="button" data-toggle="collapse" href=".weights" aria-expanded="false" aria-controls="genesets">
            Sample weights
          </a>
          <div class='weights collapse'>
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
        dge_method:
            required: true
        sel_conditions:
            required: true
        settings:
            required: true
    data: () ->
        cur:
            dge_method: this.dge_method || 'voom'
            sel_conditions: this.sel_conditions
        editing: false
    watch:
        dge_method: (v) ->
            this.cur.dge_method=v
            this.editing = false
        sel_conditions: (v,o) ->
            this.cur.sel_conditions=v
            this.editing = false
    computed:
        conditions: () ->
            this.settings.replicates.map((c,i) -> {name:c[0]})
        hidden_factors: () ->
            this.settings.hidden_factor
    methods:
        apply: () ->
            this.editing=false
            this.$emit('apply', this.cur)
        cancel: () ->
            this.editing=false
            this.cur.dge_method = this.dge_method
            this.cur.sel_conditions = this.sel_conditions

</script>
