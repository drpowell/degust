
require('./common-req.coffee')
require('./d3-req.coffee')
require("./slickgrid-req.coffee")

# Ours
config = require('./config.vue').default
Vue = require('vue').default

new Vue(
    el: '#app'
    render: (h) -> h(config)
)
