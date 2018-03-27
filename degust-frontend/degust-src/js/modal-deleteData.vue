<style scoped>
pre {
    font-size: 8pt;
}
</style>

<template>
    <div>
        <modal
            :showModal='show'
            :closeAction='close'
        >
            <h3 slot='header'>Deleting Data</h3>
            <div slot='body' class='alert alert-danger'>
                Are you sure you wish to delete your data?
            </div>
            <div slot='footer'>
                <button class='btn btn-danger' @click='deleteButton'>Delete</button>
                <button class='btn btn-primary' @click='closeButton'>Cancel</button>
            </div>
        </modal>
    </div>
</template>

<script lang='coffee'>

Modal = require('modal-vue').default

module.exports =
    name: 'modalDelete'
    components:
        modal: Modal
    props:
        show:
            default: false
    methods:
        close: () ->
            this.$emit('close')
        closeButton: () ->
            this.close()
        deleteButton: () ->
            this.$emit('destroy')
            this.close()
</script>
