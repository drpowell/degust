
require('./common-req.coffee')

require("./lib/bootstrap-tour.js")
require("./d3-req.coffee")

# Ours
require('./print.coffee')
require('./scatter3d.coffee')
require('./kegg.coffee')
require("./tour.coffee")

# Ours
compare = require('./compare.vue').default
global.Vue = Vue = require('vue').default

# Create a plugin to stop objects being observed
Vue.use(
    install: (Vue) ->
        Vue.noTrack = (o) -> Object.preventExtensions(o)
)

new Vue(
    name: 'app'
    el: '#replace-me'
    render: (h) -> h(compare)
)
