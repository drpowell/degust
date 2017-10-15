<style scoped>
    .volcano-plot { height: 330px; }

    div.tooltip {
      position: absolute;
      text-align: center;
      padding: 2px;
      font: 12px sans-serif;
      background: #333;
      color: #fff;
      border: 0px;
      border-radius: 8px;
      pointer-events: none;
      width: 200px;
      opacity: 0.8;
    }

    div.tooltip table {
      font: 12px sans-serif;
      color: #fff;
    }

</style>

<template>
    <div>
        <scatter-plot class='volcano-plot'
                      yaxis-loc='zero'
                      :data='data'
                      :x-column='xColumn' :y-column='yColumn'
                      :colour='colour'
                      :highlight='highlight'
                      :brush-enable='true' :canvas='true'
                      @mouseover='show_info'
                      @mouseout='hide_info'
                      @brush='brushed'
                      >
        </scatter-plot>
        <div class='tooltip' v-if='hover.length>0' :style="tooltipStyle">
            <table>
                <tr v-for='c in infoCols'>
                    <td><b>{{c.name}}:</b></td>
                    <td>{{hover[0][c.idx]}}</td>
                </tr>
                <tr><td><b>Ave Expr:</b></td><td>{{fmt(hover[0][avgCol.idx])}}</td></tr>
                <tr><td><b>log FC:</b></td><td>{{fmt(hover[0][logfcCol.idx])}}</td></tr>
                <tr><td><b>FDR:</b></td><td>{{fmt2(hover[0][fdrCol.idx])}}</td></tr>
                <tr><td><b>-log10 FDR:</b></td><td>{{fmt(-Math.log10(hover[0][fdrCol.idx]))}}</td></tr>
            </table>
            <div v-if='hover.length>1'>
                And {{hover.length-1}} other{{hover.length>2 ? 's' : ''}}
            </div>
        </div>
    </div>

</template>

<script lang='coffee'>

scatter = require('./scatter-plot.vue').default

module.exports =
    components:
        scatterPlot: scatter
    props:
        data: null
        avgCol: null
        logfcCol : null
        colour: null
        infoCols: null
        fdrCol: null
        highlight: null
    data: () ->
        hover: []
        tooltipLoc: [0,0]
    computed:
        xColumn: () ->
            xCol = this.logfcCol
            if xCol?
                {name: "log FC", get: (d) => d[xCol.idx] }
            else
                null
        yColumn: () ->
            yCol = this.fdrCol
            if yCol?
                {name: "-log10 FDR", get: (d) => -Math.log10(d[yCol.idx]) }
            else
                null
        tooltipStyle: () ->
            {left: (this.tooltipLoc[0]+40)+'px', top: (this.tooltipLoc[1]+35)+'px'}
    methods:
        fmt: (val) -> val.toFixed(2)
        fmt2: (val) -> if val<0.01 then val.toExponential(2) else val.toFixed(2)

        brushed: (d) ->
            this.$emit('brush', d)
        show_info: (d,loc) ->
            this.hover=d
            this.tooltipLoc = loc
        hide_info: () ->
            this.hover=[]

</script>
