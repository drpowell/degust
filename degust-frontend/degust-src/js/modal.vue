
<style scoped>
.modal {
    position: fixed;
    overflow: auto;
}
</style>

<template>
    <div :class="containerClass">
        <div :class="{modal: true, in: showModal}" :style="{ display: showModal ? 'block' : 'none' }" @click='mayClose'>
            <div class="modal-dialog" @click.stop=''>
                <div class="modal-content">
                    <div v-if="this.$slots.header || closeAction" class="modal-header">
                        <button class="close" @click.prevent="mayClose">x</button>
                        <slot name="header"></slot>
                    </div>
                    <div v-if="this.$slots.body" class="modal-body">
                        <slot name="body"></slot>
                    </div>
                    <div v-if="this.$slots.footer" class="modal-footer">
                        <slot name="footer"></slot>
                    </div>
                </div>
            </div>
        </div>
        <div :class="{'modal-backdrop': showModal, in: showModal}"></div>
    </div>
</template>

<script lang='coffee'>
# This modal was original copied from : https://github.com/colinf/modal-vue
module.exports =
    props:
        showModal: Boolean,
        closeAction: Function,
        containerClass: String
    methods:
        mayClose: () ->
            if this.closeAction?
                this.closeAction()
        keyHandler: (e) ->
            if (this.showModal && e.keyCode == 27 && this.closeAction?)
                this.closeAction()
    beforeDestroy: () ->
        document.removeEventListener('keydown', this.keyHandler)
    mounted: () ->
        document.addEventListener("keydown", this.keyHandler)
</script>
