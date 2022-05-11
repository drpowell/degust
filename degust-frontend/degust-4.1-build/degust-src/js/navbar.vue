<style scoped>
/* Log message panel ****************************************************/

.log-list {
    position: absolute;
    top: 60px;
    right: 60px;

    border: thin solid black;
    background: #ddd;
    padding: 5px;
    border-radius: 5px;
    z-index: 99;
    max-height: 600px;
    overflow: scroll;
}

.log-list .error { color: red; }
.log-list .warn { color: yellow; }
.log-list .info { color: blue; }

.log-link { opacity: 0.4; }

</style>
<template>
<div>
    <div class="navbar navbar-inverse navbar-static-top">
        <div class="container">
            <div class="navbar-header">
            <button type="button" class="navbar-toggle" data-toggle="collapse" data-target="#right-navbar-collapse">
                <span class="sr-only">Toggle navigation</span>
                <span class="icon-bar"></span>
                <span class="icon-bar"></span>
                <span class="icon-bar"></span>
            </button>

            <a class="navbar-brand" :href="homeLink">{{ degustName }} : </a>
            <span class="navbar-brand">{{ experimentName }}</span>
            </div>

            <ul class="nav navbar-nav navbar-right navbar-collapse collapse" id="right-navbar-collapse">
                <li><a @click='show_log_list = !show_log_list' class='log-link'>Logs</a></li>
                <!-- <li><a id="tour" href="#">Tour</a></li> -->
                <slot name="switchURL"></slot>

                <slot name="qclist"></slot>

                <li><a @click='show_about'>About</a></li>
                <ul class="nav navbar-nav navbar-right navbar-collapse collapse"
                    v-html='fullSettings.extra_menu_html' v-if='fullSettings.extra_menu_html'>
                </ul>
            </ul>
        </div>
    </div>

    <div v-show='show_log_list' class='log-list'>
    <h4>Log messages</h4>
    </div>
</div>
</template>

<script lang='coffee'>

module.exports =
    name: 'navbar'

    props:
        homeLink: null
        canConfigure: null
        canView: null
        fullSettings: null
        extraMenuHtml: null
        experimentName: null
        uniqueCode: null
        degustName: null

    data: () ->
        show_log_list: false

    computed:
        null

    methods:
        qc_plots: (plot) ->
            this.$emit('qcplot', plot)
        show_about: () ->
            this.$emit('showAbout', true)

</script>