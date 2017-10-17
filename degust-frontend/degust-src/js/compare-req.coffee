
require('./common-req.coffee')

require("./lib/bootstrap-tour.js")
require("./d3-req.coffee")

# Ours
require('./print.coffee')
require('./heatmap.coffee')
require('./scatter3d.coffee')
require('./kegg.coffee')
require("./tour.coffee")
require('./normalize.coffee')

# Ours
compare = require('./compare.vue').default
global.Vue = Vue = require('vue').default

new Vue(
    name: 'app'
    el: '#replace-me'
    render: (h) -> h(compare)
)
