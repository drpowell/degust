<style scoped>
.text-right { text-align:right }
</style>

<template>
    <div>
        <modal :showModal='showInteraction'>
            <div slot='body'>
                Interaction :
                <div>(
                    <select v-model='term1'><option v-for='(rep,idx) in conditions' v-bind:value='idx'>{{rep.name}}</option></select>
                    -
                    <select v-model='term2'><option v-for='(rep,idx) in conditions' v-bind:value='idx'>{{rep.name}}</option></select>
                    )
                </div>
                <div>-</div>
                <div>(
                    <select v-model='term3'><option v-for='(rep,idx) in conditions' v-bind:value='idx'>{{rep.name}}</option></select>
                    -
                    <select v-model='term4'><option v-for='(rep,idx) in conditions' v-bind:value='idx'>{{rep.name}}</option></select>
                    )
                </div>
                <button v-on:click='closeInteraction' type="button" class="btn btn-primary" title="" data-placement='right'>
                    Ok
                </button>
            </div>
        </modal>

        <div v-if='conditions.length>=4'>
            <button v-on:click='showInteraction=true' type="button" class="btn btn-primary" title="" data-placement='right'>
                Create Interaction
            </button>
        </div>
        <table>
            <tr>
                <td></td>
                <td>
                    <input size=15 v-model='contrast.name' placeholder="Unnamed"/>
                </td>
            </tr>
            <tr v-for='(rep,idx) in conditions'>
                <th>{{rep.name}}</th>
                <td>
                    <input size=15 v-model.number='contrast.column[idx]' class='text-right' />
                </td>
            </tr>
        </table>
    </div>
</template>


<script lang="coffee">

Multiselect = require('vue-multiselect').default
Modal = require('modal-vue').default

module.exports =
    components:
        Multiselect: Multiselect
        modal: Modal
    props:
        conditions:         # Array of hashes.  Each hash has "rep.name" for name of the condition
            required: true
            default: () ->  []
        edit:
            required: true
            default: () ->  null
    data: () ->
        term1: null
        term2: null
        term3: null
        term4: null
        showInteraction: false
        contrast:
            name: null
            column: []
    watch:
        conditions: () ->
            this.contrast.column = Array(this.conditions.length).fill(0)
    methods:
        closeInteraction: () ->
            if this.term1? && this.term2 && this.term3 && this.term4
                this.contrast.column[this.term1]=1
                this.contrast.column[this.term2]=-1
                this.contrast.column[this.term3]=1
                this.contrast.column[this.term4]=-1
                if !this.contrast.name? || this.contrast.name==""
                    this.contrast.name = "Interaction"
            this.showInteraction=false
    mounted: () ->
        if this.edit?
            this.contrast.column = Array(this.conditions.length).fill(0)
            col = this.edit.column
            if col?
                this.contrast.column.forEach((x,i) => this.contrast.column[i] = col[i] || 0)
            this.contrast.name = this.edit.name
</script>
