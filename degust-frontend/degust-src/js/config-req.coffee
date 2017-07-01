

# Ours
config = require('./config.vue')
Vue = require('./lib/vue')

new Vue(
    el: '#app'
    render: (h) -> h(config)
)
