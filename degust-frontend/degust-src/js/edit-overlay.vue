<!--
  Component to allow editing that can be canceled
  It will show an "overlay" over the reset of the screen
 And add a "apply" and "cancel" buttton.  With events for each
-->

<style scoped>
.edit-overlay {
    position: fixed;
    top:0;
    bottom: 0;
    left: 0;
    right: 0;
    background-color: black;
    opacity: 0.4;
    z-index: 10000;
}

.edit-backdrop {
    position: absolute;
    border-radius: 5px;
    background: white;
    z-index: 10000;
}

.edit-elem {
    position: relative;
    z-index: 10001;
}

.edit-btns {
    padding: 2px;
}
</style>

<template>
    <div>
        <div :class="{'edit-elem': enabled}" ref='editElem'>
            <slot>Editable component</slot>
            <div class="edit-btns" v-if='enabled && showButtons'>
                <button class='btn btn-default btn-sm' @click='cancel'>Cancel</button>
                <button class='btn btn-primary btn-sm' @click='apply' :disabled='!valid'>Apply</button>
            </div>
        </div>
        <div class="edit-overlay" v-if='enabled' @click='$emit("bg-click")'></div>
        <div class="edit-backdrop" v-if='enabled' :style='backdropStyle'></div>
    </div>
</template>

<script lang='coffee'>
module.exports =
    props:
        enabled:
            required: true
        showButtons:
            default: true
        valid:
            default: true
        needUpdate:
            default: 0
    data: () ->
        backdropStyle:
            top: 0
            left: 0
            width: 0
            height: 0
    watch:
        enabled: () ->
            this.placeBackdrop()
        needUpdate: () ->
            this.placeBackdrop()
    mounted: () ->
        this.placeBackdrop()
    methods:
        cancel: () -> this.$emit('cancel')
        apply: () -> this.$emit('apply')
        placeBackdrop: () ->
            if this.enabled
                this.$nextTick( () =>
                    this.backdropStyle =
                        top:    this.$refs.editElem.offsetTop-10
                        left:   this.$refs.editElem.offsetLeft-10
                        width:  this.$refs.editElem.offsetWidth+20
                        height: this.$refs.editElem.offsetHeight+20
                )

</script>
