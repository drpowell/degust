<template>
    <modal
        :showModal='show'
        :closeAction='close'
    >
        <h4 slot='header'>Experiment Description</h4>
        <div slot='body'>
            <pre v-if='desc != ""'>{{ desc }}</pre>
            <pre v-else>No Experiment Description to show.</pre>
        </div>
        <div slot='footer'>
            <button class='btn btn-primary' @click='closeButton'>Close</button>
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
        desc: ""
    methods:
        close: () ->
            this.$emit('close')
        closeButton: () ->
            this.close()
</script>
