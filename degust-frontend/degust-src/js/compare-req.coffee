
require("./lib/bootstrap-tour.js")
require("./lib/numeric-1.2.6.js")

# Ours
require('./print.coffee')
require('./slider.coffee')
require('./gene_table.coffee')
require('./parcoords.coffee')
require('./scatter-plot.coffee')
require('./ma-plot.coffee')
require('./volcano-plot.coffee')
require('./heatmap.coffee')
require('./bargraph.coffee')
require('./scatter3d.coffee')
require('./pca.coffee')
require('./kegg.coffee')
require("./tour.coffee")
require("./edit-list.coffee")
require('./normalize.coffee')
require('./qc.coffee')
require('./gene-expression.coffee')

# Ours
compare = require('./compare.vue')
Vue = require('./lib/vue')

new Vue(
    el: '#replace-me'
    render: (h) -> h(compare)
)
