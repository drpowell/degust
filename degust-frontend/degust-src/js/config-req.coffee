
require('./common-req.coffee')
require('./d3-req.coffee')

# Ours
config = require('./config.vue').default
global.Vue = Vue = require('vue').default
VTooltip = require('v-tooltip').default

# Install tooltips
Vue.use(VTooltip)
VTooltip.options.defaultClass = 'v-tooltip'

# Create a plugin to stop objects being observed
Vue.use(
    install: (Vue) ->
        Vue.noTrack = (o) -> Object.preventExtensions(o)
)

new Vue(
    el: '#app'
    render: (h) -> h(config)
)
