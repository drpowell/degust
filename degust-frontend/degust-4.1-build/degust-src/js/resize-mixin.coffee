
# This mixin listens to resize events from the parent component

module.exports =
    mounted: () ->
        this.$parent.$on('resize', this.resize)
    beforeDestroy: () ->
        this.$parent.$off('resize', this.resize)
    methods:
        resize: () ->
            console.log "WARNING : implementation of resize() missing from component"
