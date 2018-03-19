<style scoped>
td, th {
    border: 1px solid #dddddd;
    text-align: left;
    padding: 8px;
    font-size: 7pt;
}



</style>
<template>
    <div>
        <modal
            :showModal='show'
            :closeAction='close'
        >
            <h6 slot='header'>Extra Information</h6>
            <div slot='body' style="overflow-x: auto;">
                <!-- <select v-if='extraInfoData != null' v-model="selectShown">
                    <option v-for='entry of Object.keys(extraInfoData)' :value='entry'>{{entry}}</option>
                </select> -->
                <table v-if='formatData() != null'>
                    <tr>
                        <th v-for='samples of formatData().samples'>{{ samples }}</th>
                    </tr>
                    <tr>
                        <td v-for='weights of formatData().weights'>{{ weights }}</td>
                    </tr>
                </table>
            </div>
            <div slot='footer'>
                <button class='btn btn-primary' @click='closeButton'>Close</button>
            </div>
        </modal>
    </div>
</template>

<script lang='coffee'>

Modal = require('modal-vue').default

module.exports =
    name: 'extraInfo'
    components:
        modal: Modal
    props:
        show: false
        extraInfoData: null
    data: () ->
        selectShown: if this.extraInfoData? then Object.keys(this.extraInfoData)[0] else ""
    methods:
        close: () ->
            this.$emit('close')
        closeButton: () ->
            this.close()
        formatData: () ->
            if this.extraInfoData?
                {weights: this.extraInfoData.sample_weights, samples: this.extraInfoData.samples}
</script>
