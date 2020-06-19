<style scoped>
.text-right { text-align:right; }
</style>

<template>
    <div>
        <div class='row' v-for='(col,idx) in columns_visible' :key='idx' >
            <div class="col-sm-6">
                {{col.orig}}
            </div>
            <div class="col-sm-4">
                <input v-model.trim='col.name' class="form-control" type="text" :placeholder="col.orig" size='15' />
            </div>
            <div class="col-sm-1">
                <button v-on:click='col.hide=!col.hide' type="button" tabindex=-1>&times;</button>
            </div>
        </div>
        <hr/>
        <div class='row'>
            <div class="col-sm-1">
                <button v-on:click='clearAll' type="button" class="btn btn-default btn-sm" tabindex=-1 v-tooltip="tip('Clear all')"><span class="glyphicon glyphicon-trash" aria-hidden="true"></span></button>
            </div>
            <div class="col-sm-1">
                <button v-on:click='showModal=true' type="button" class="btn btn-default btn-sm" tabindex=-1 v-tooltip="tip('Use a regexp to configure')"><span class="glyphicon glyphicon-flash" aria-hidden="true"></span></button>
            </div>
            <div class="col-sm-6">
                <input type="checkbox" id='show_all' v-model="showAll">
                <label for="show_all">Show all</label>
            </div>
            <div class="col-sm-2">
                <button v-on:click='fireClose' type="button" class="btn btn-default">Apply</button>
            </div>
            <div class="col-sm-2">
                <button v-on:click='fireCancel' type="button" class="btn btn-default">Cancel</button>
            </div>
        </div>
        <modal :showModal="showModal" :closeAction="closeModal">
            <div slot="body">
                <div class='row'>
                    <div class="col-sm-8">
                        <input v-model='regex' placeholder='regex' size=40 type="text" />
                    </div>
                    <div class="col-sm-1">
                        <button v-on:click='applyRegex' type="button">Apply</button>
                    </div>
                    <div class="col-sm-1">
                        <button v-on:click='closeModal' type="button">Cancel</button>
                    </div>
                </div>
                <div>
                    <div class='row'>
                        <div class="col-sm-12">
                            <small>Warning: Expert feature</small>
                        </div>
                    </div>
                    <div class='row'>
                        <div class="col-sm-12">
                            <small>Enter a javascript regexp to rename samples.  Groups () will be used for the new names.</small>
                        </div>
                    </div>
                </div>
            </div>
        </modal>
    </div>
</template>

<script lang="coffee">

module.exports =
    props:
        columns:
            required: true
            default: () ->  []
        niceNames:
            required: true
            default: () ->  {}
    data: () ->
        localNiceNames: this.init_local_nice_names(this.niceNames)
        showAll: false
        showModal: false
        regex: ""
    computed:
        columns_visible: () ->
            this.columns.map((c) => this.localNiceNames[c]).filter((col) => this.showAll || !col.hide)
    methods:
        fireCancel: () ->
            this.$emit('close',null)
        fireClose: () ->
            this.$emit('close',this.localNiceNames)
        clearAll: () ->
            this.localNiceNames = Vue.observable(this.init_local_nice_names({}))
        init_local_nice_names: (obj) ->
            ret = JSON.parse(JSON.stringify(obj))
            this.columns.forEach((c) ->
                if (!(c of ret))
                    ret[c]={}
                    ret[c].hide = false
                    ret[c].name = ""
                    ret[c].orig = c
            )
            ret
        closeModal: () ->
            this.showModal = false
        applyRegex: () ->
            re = RegExp(this.regex, "i")
            for c, col of this.localNiceNames
                if this.showAll || !col.hide
                    m = col.orig.match(re)
                    if m && m.length>1
                        col.name = m[1..].join('-')
            this.closeModal()
        tip: (txt) ->
            {content:txt, placement:'right'}

</script>
