<template>
    <modal
        :showModal='show'
        :closeAction='close'
    >
        <h4 slot='header'>Filter to this gene list</h4>
        <div slot='body'>
            <textarea style="width:100%;height:150px;resize:vertical;" v-model="filterGeneList" placeholder="Type or paste your delimited genes here"></textarea>
        </div>
        <div slot='footer'>
            <button class='btn btn-primary' @click='clearList'>Clear</button>
            <button class='btn btn-primary' @click='closeButton'>Apply</button>
        </div>
    </modal>
</template>

<script lang='coffee'>

Modal = require('modal-vue').default

module.exports =
    name: 'filterGenes'
    data: () ->
        filterGeneList: ""
    components:
        modal: Modal
    props:
        show: false
    methods:
        clearList: () ->
            this.filterGeneList = ""
        filterList: () ->
            genelist = this.filterGeneList
            res = genelist.toLowerCase().split(/,|\n|\t/).map((el) -> el.trim()).filter((el) -> el.length > 0)
            this.$emit('filterList', res);
        close: () ->
            this.$emit('close')
        closeButton: () ->
            this.filterList()
            this.close()
</script>
