compareSingle = require('./compare-single.vue').default

module.exports =
    name: 'compare-main'
    components:
        compareSingle: compareSingle
    data: () ->
        home_link: null
        experimentName:
            default: () -> ""
        full_settings: null         # FIXME: this shouldn't be here

    computed:
        globalCode: () -> get_url_vars()["code"]
        globalSettings: () -> window.settings

    methods:
        null

    mounted: () ->
        #this.parse_url_params(this.$route.query)

        # TODO : ideally just this component, not window.  But, need ResizeObserver to do this nicely
        window.addEventListener('resize', () => this.$emit('resize'))
