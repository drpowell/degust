<style scoped>
pre {
    font-size: 8pt;
}
</style>

<template>
    <div v-if='errorMsg != null'>
        <modal
            :showModal='show'
            :closeAction='close'
        >
            <h3 slot='header'>Error</h3>
            <div slot='body'>
                Error Message:
                <pre>{{ errorMsg.msg }}</pre>
                <div v-if='errorMsg.input != null'>
                    Input
                    <pre>{{ errorMsg.input }}</pre>
                </div>
            </div>
            <div slot='footer'>
                <button class='btn btn-primary' @click='closeButton'>Close</button>
            </div>
        </modal>
    </div>
</template>

<script lang='coffee'>

Modal = require('modal-vue').default

module.exports =
    name: 'DGEErrorMsg'
    components:
        modal: Modal
    props:
        show: false
        errorMsg: null
    methods:
        close: () ->
            this.$emit('close')
        closeButton: () ->
            this.close()
</script>
