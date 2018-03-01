<style scoped>

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

            <a class="navbar-brand" :href="homeLink">Degust : </a>
            <span class="navbar-brand">{{ experimentName }}</span>
            </div>

            <ul class="nav navbar-nav navbar-right navbar-collapse collapse" id="right-navbar-collapse">
            <li><a class="log-link" href="#">Logs</a></li>
            <!-- <li><a id="tour" href="#">Tour</a></li> -->
            <slot name="switchURL"></slot>

            <slot name="qclist"></slot>

            <li><a @click='show_about'>About</a></li>
            <ul class="nav navbar-nav navbar-right navbar-collapse collapse"
                v-html='fullSettings.extra_menu_html' v-if='fullSettings.extra_menu_html'>
            </ul>
            <li class="dropdown" v-if='fullSettings.versions'>
                <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false">
                <span class="glyphicon glyphicon-cog"></span>
                </a>
                <ul class="dropdown-menu">
                <li v-for="ver in fullSettings.versions"><a :href='ver.path+"?code="+uniqueCode'>{{ ver.version }}</a></li>
                </ul>
            </li>
            </ul>
        </div>
        </div>

        <div class='log-list'>
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

    computed:
        null

    methods:
        qc_plots: (plot) ->
            this.$emit('qcplot', plot)
        show_about: () ->
            this.$emit('showAbout', true)

</script>