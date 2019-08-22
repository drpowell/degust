
require('./common-req.coffee')

require("./lib/bootstrap-tour.js")
require("./d3-req.coffee")

# Ours
require('./print.coffee')

# Ours
compare = require('./compare-main.vue').default
global.Vue = Vue = require('vue').default

# Install tooltips
VTooltip = require('v-tooltip').default
Vue.use(VTooltip)
VTooltip.options.defaultClass = 'v-tooltip'

VueAWN = require('vue-awesome-notifications').default
AWNOptions =
    position: 'top-right'
    durations:
        warning: 0
    icons:
        enabled: false
Vue.use(VueAWN, AWNOptions)

# Use vue-router for tracking state in URL
VueRouter = require('vue-router').default
router = new VueRouter(
    mode: 'hash'
    base: window.location.href
    routes: [
        {name:'home', path: '/'}
    ]
)


# global state.  Use sparingly!
shared = new Vue(
    data: () ->
        asset_base: ''
)


# Create a plugin to stop objects being observed
Vue.use(
    install: (Vue) ->
        Vue.noTrack = (o) -> Object.preventExtensions(o)
        Object.defineProperty(Vue.prototype, '$global',
            get: () -> shared
        )
)

# Global registration of modal, as it is used in many places
Modal = require('./modal.vue').default
Vue.component('modal', Modal)


new Vue(
    name: 'app'
    el: '#replace-me'
    router: router
    render: (h) -> h(compare)
)
