<style scoped>
td, th {
    border: 1px solid #dddddd;
    text-align: left;
    padding: 8px;
    font-size: 7pt;
}

#missData {
    font-size: 7pt;
    overflow: auto;
}

</style>
<template>
    <div>
        <modal
            :showModal='show'
            :closeAction='close'
        >
            <h6 slot='header'>Extra Information</h6>
            <div v-if='extraInfoData != null' slot='body' style="overflow: auto;">
                <select v-model="selectShown">
                    <option v-for='entry of extraInfo' :value='entry'>{{entry}}</option>
                </select>
                <!-- Sample Weights -->
                <table v-if='selectShown == "sample_weights"'>
                    <tr>
                        <th v-for='samples of formatData("sample_weights").samples'>{{ samples }}</th>
                    </tr>
                    <tr>
                        <td v-for='weights of formatData("sample_weights").weights'>{{ weights }}</td>
                    </tr>
                </table>
                <!-- Rank -->
                <table v-else-if='selectShown == "rank"'>
                    <tr>
                        <th>Rank</th><td>{{ formatData("rank") != null ? formatData("rank")[0] : undefined}}</td>
                    </tr>
                </table>
                <!-- df_prior -->
                <table v-else-if='selectShown == "df_prior"'>
                    <tr>
                        <th>DF Prior</th><td>{{ formatData("df_prior")[0] }}</td>
                    </tr>
                </table>
                <!-- prior_df -->
                <table v-else-if='selectShown == "prior_df"'>
                    <tr>
                        <th>DF Prior</th><td>{{ formatData("prior_df")[0] }}</td>
                    </tr>
                </table>
                <!-- Design -->
                <table v-else-if='selectShown == "design"'>
                    <th></th>
                    <th v-for='group of formatData("design")[0].groups'>{{ group }}</th>
                    <tr v-for='design of formatData("design")'>
                        <th>{{ design.sample }}</th><td v-for='members of design.membership'>{{ members }}</td>
                    </tr>
                </table>
                <!-- Contrasts -->
                <table v-else-if='selectShown == "contrasts"'>
                    <th></th>
                    <th v-for='group of formatData("contrasts")[0].groups'>{{ group }}</th>
                    <tr v-for='design of formatData("contrasts")'>
                        <th>{{ design.sample }}</th><td v-for='members of design.membership'>{{ members }}</td>
                    </tr>
                </table>
                <!-- Cov_coefficients -->
                <table v-else-if='selectShown == "cov_coefficients"'>
                    <th></th>
                    <th v-for='group of formatData("cov_coefficients")[0].groups'>{{ group }}</th>
                    <tr v-for='design of formatData("cov_coefficients")'>
                        <th>{{ design.sample }}</th><td v-for='members of design.membership'>{{ members }}</td>
                    </tr>
                </table>
                <!-- Catch all else -->
                <pre id='missData' v-else>{{ formatData(selectShown) }}</pre>
            </div>
            <div v-if='extraInfoData == null'>
                There is no Extra Info to show.
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
        infoShown: ""
        exclude: ["normalize", "samples"]
    computed:
        selectShown:
            get: () ->
                if this.extraInfoData? && this.infoShown == ""
                    this.infoShown = this.extraInfo[0]
                this.infoShown
            set: (val) ->
                this.infoShown = val
        extraInfo: () ->
            Object.keys(this.extraInfoData).filter((val) => this.exclude.indexOf(val) < 0)
    methods:
        close: () ->
            this.$emit('close')
        closeButton: () ->
            this.close()
        formatData: (type) ->
            if this.extraInfoData?
                if Object.keys(this.extraInfoData).indexOf(type) >= 0
                    switch
                        when type == "sample_weights"
                            {weights: this.extraInfoData.sample_weights, samples: this.extraInfoData.samples}
                        when type == "rank"
                            this.extraInfoData.rank
                        when type == "df_prior"
                            this.extraInfoData.df_prior
                        when type == "prior_df"
                            this.extraInfoData.prior_df
                        when type == "design"
                            this.extraInfoData.design.map((el) ->
                                shortKeys = Object.keys(el).slice(0, Object.keys(el).length-1)
                                {groups: shortKeys, membership: shortKeys.map((key) -> el[key]), sample:el["_row"]}
                            )
                        when type == "samples"
                            this.extraInfoData.samples
                        when type == "contrasts"
                            this.extraInfoData.contrasts.map((el) ->
                                shortKeys = Object.keys(el).slice(0, Object.keys(el).length-1)
                                {groups: shortKeys, membership: shortKeys.map((key) -> el[key]), sample:el["_row"]}
                            )
                        when type == "cov_coefficients"
                            this.extraInfoData.cov_coefficients.map((el) ->
                                shortKeys = Object.keys(el).slice(0, Object.keys(el).length-1)
                                {groups: shortKeys, membership: shortKeys.map((key) -> el[key]), sample:el["_row"]}
                            )
                        else
                            this.extraInfoData[type]
</script>
