<style scoped>
.ontop { z-index: 10; }
div >>> label {
    color: black;
    font-size: 10pt;
}
</style>

<template>
    <div v-on-clickaway='close'>
        <style-menu>
            <vue-menu ref="menu"  class='ontop'>
                <slot>
                </slot>
            </vue-menu>
        </style-menu>
    </div>
</template>

<script lang='coffee'>

# vue-menu
{ Menu, Menuitem,StyleBlack,StyleMetal } = require('@hscmap/vue-menu')
clickaway = require('vue-clickaway').mixin

module.exports =
    name: 'popup-menu'
    components:
        VueMenu: Menu
        VueMenuItem: Menuitem
        StyleMenu: StyleMetal
    mixins: [clickaway]
    methods:
        open: (x,y,dir) ->
            this.$refs.menu.open(x,y,dir)
        close: () ->
            this.$refs.menu.close()

        show: (ev) ->
            ev.stopPropagation()
            if this.$refs.menu.isOpen
                this.close()
            else
                this.open(ev.x,ev.y,"left")


</script>