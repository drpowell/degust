
require('./common-req.coffee')

require("./lib/bootstrap-tour.js")
require("./d3-req.coffee")

# Ours
require('./print.coffee')
require('./kegg.coffee')
require("./tour.coffee")

# Ours
compare = require('./compare.vue').default
global.Vue = Vue = require('vue').default
VueRouter = require('vue-router').default

# Use vue-router for tracking state in URL
router = new VueRouter(
    mode: 'hash'
    base: window.location.href
    routes: [
        {name:'home', path: '/'}
    ]
)

# Create a plugin to stop objects being observed
Vue.use(
    install: (Vue) ->
        Vue.noTrack = (o) -> Object.preventExtensions(o)
)

new Vue(
    name: 'app'
    el: '#replace-me'
    router: router
    render: (h) -> h(compare)
)
