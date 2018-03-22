<style scoped>
#body {
    height: 250px;
    overflow-y: auto;
    }

</style>

<template>
    <modal
        :showModal='show'
        :closeAction='close'
    >
        <h4 slot='header'>Select columns to display</h4>

        <div slot='body' id='body'>
            <div>
                <table>
                    <tr v-for='col of colData' v-if='colData'>
                            <th>{{col.name}}</th><td><input type='checkbox' :value='col' v-model='selectedCols'></td>
                    </tr>
                </table>
            </div>
        </div>
        <div slot='footer'>
            <h5 v-if='showValidColumns' class='alert alert-warning'>Please select at least one column</h5>
            <div>
                <button class='btn btn-primary' style='float:left;' @click='removeAll'>Deselect All</button>
                <button class='btn btn-primary' style='float:left;' @click='addAll'>Select All</button>
                <button class='btn btn-primary' @click='closeButton'>Apply</button>
            </div>
        </div>
    </modal>
</template>

<script lang='coffee'>

Modal = require('modal-vue').default

module.exports =
    name: 'filterGenes'
    data: () ->
        filterGeneList: ""
    components:
        modal: Modal
    props:
        show: false
        allColData: null
        defaultCols: null
        colTypes: null
    data: () ->
        checkedNames: null
        showValidColumns: false
    computed:
        colData:
            get: () ->
                colType = this.colTypes
                if this.allColData?
                    subCol = []
                    this.allColData.forEach((el) =>
                        if colType.indexOf(el.type) >= 0
                            subCol.push(el)
                    )
                    subCol
                else
                    null
            set: (val) ->
                val
        selectedCols:
            get: () ->
                if !this.checkedNames? && this.defaultCols.length > 0
                    this.checkedNames = this.defaultCols
                this.checkedNames
            set: (val) ->
                if val.length == 0
                    this.showValidColumns = true
                    this.checkedNames = []
                    return
                else
                    this.showValidColumns = false
                    this.checkedNames = val
    methods:
        close: () ->
            this.$emit('close')
        closeButton: () ->
            if this.selectedCols.length == 0
                return
            this.$emit('columnsToShow', this.selectedCols)
            this.close()
        addAll: () ->
            this.selectedCols = this.colData
        removeAll: () ->
            this.selectedCols = []
</script>
