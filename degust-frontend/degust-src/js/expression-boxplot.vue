<style scoped>
/* Boxplot (also see d3.boxplot.css) *****************************************************/

.box-plot >>> .axis path, .box-plot >>> .axis line {
  fill: none;
  stroke: #000;
  shape-rendering: crispEdges;
}

</style>

<template>
    <div class='box-plot'>
        <svg>
        </svg>
        <div>
            <label>Normalized</label>
            <select v-model='normalization'>
                <option v-for='e in availNormalization' :value='e.key'>{{e.name}}</option>
            </select>
        </div>
    </div>
</template>

<script lang='coffee'>

require("./lib/d3.boxplot.js")
{ Normalize } = require('./normalize.coffee')

iqr = (k) ->
    (d,i) ->
        q1 = d.quartiles[0]
        q3 = d.quartiles[2]
        r = (q3 - q1) * k
        i = -1
        j = d.length
        while (d[++i] < q1 - r)
            i=i
            # Do nothing
        while (d[--j] > q3 + r)
            i=i
            # Do nothing
        [i, j]

module.exports =
    name: 'expression-boxplot'
    props:
        geneData: null
        getNormalized: null
        availNormalization: null
        colour:
            type: Function
            default: d3.scale.category10()
        isRle:
            type: Boolean
            default: false
    data: () ->
        normalization: 'cpm'
        normalization_cols: []

    watch:
        normalization: () ->
            this.calc_normalization()

    computed:
        columns: () ->
            this.geneData.columns_by_type('count')

        # Actually log-cpm
        cpm: () ->
            cols = this.normalization_cols
            cpm = cols.map((c) =>
                vals = this.geneData.get_data().map((r) -> r[c.idx])
                {vals: vals, name:this.geneData.nice_name(c.name), parent:c.parent}
            )
            Vue.noTrack(cpm)

        rle: () ->
            # https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0191629
            cpm = this.cpm
            medians = cpm[0].vals.map((_v,i) -> d3.median(cpm.map((c) -> c.vals[i])))
            rle = cpm.map((c) =>
                {name: this.geneData.nice_name(c.name), parent:c.parent, vals: c.vals.map((v,i) -> v - medians[i])}
            )
            Vue.noTrack(rle)
    methods:
        calc_normalization: () ->
            this.getNormalized(this.normalization, 0.5)
                .then((cols) =>
                    this.normalization_cols = cols;
                    this.render()
                )

        render: () ->
            if this.columns.length==0
                this.$el.innerHTML = "Error: No conditions selected"
                return

            if this.isRle
                data_per_sample = this.rle
                yLabel = ""
                title = "Relative Log Expression (from CPM, whiskers:[min,max])"
                # Whiskers are min to max
                whiskers = (vals) -> [0, vals.length-1]
            else
                data_per_sample = this.cpm
                yLabel = "log(cpm)"
                title = "Log CPM by library. (whiskers:[min,max])"
                whiskers = (vals) -> [0, vals.length-1] # iqr(1.5)

            margin = {top: 40, right: 50, bottom: 200, left: 50}
            width_box = 40
            width = width_box * data_per_sample.length + margin.left + margin.right
            box_height = 400
            height = box_height + margin.top + margin.bottom

            chart = d3.box()
                    .whiskers(whiskers)
                    .width(width_box/2)
                    .height(box_height)
                    .show_values(false)
                    .fill((c) => this.colour(c.parent))

            extent = d3.extent([].concat.apply([], data_per_sample.map((r) -> d3.extent(r.vals))))
            chart.domain(extent)

            svg = d3.select(this.$el)
                .select("svg")
                .attr('height', height)
                .attr('width', width)
            svg.selectAll("*").remove()
            svg.append("text")
                .attr('class', 'title')
                .attr("x", width/2)
                .attr("y", 15)
                .style("text-anchor", "middle")
                .text(title)

            # the x-axis
            x = d3.scale.ordinal()
                .domain( data_per_sample.map((c) -> c.name) )
                .rangeRoundBands([0 , width_box * (data_per_sample.length-1)], 0.7, 0.3)

            svg.selectAll("g.boxplot")
            .data(data_per_sample)
            .enter().append("g")
            .attr("class","boxplot")
            .attr("transform", (d) -> "translate(" + (margin.left + x(d.name)) + "," + margin.top + ")")
            .call(chart)

            xAxis = d3.svg.axis()
                    .scale(x)
                    .orient("bottom")

            # the y-axis
            y = d3.scale.linear()
                .domain(extent)
                .range([box_height + margin.top, 0 + margin.top])

            yAxis = d3.svg.axis()
                    .scale(y)
                    .orient("left")
            # draw y axis
            svg.append("g")
                .attr("class", "y axis")
                .attr("transform", "translate("+(margin.left-20)+",0)")
                .call(yAxis)
                .append("text")
                .attr("transform", "rotate(-90)")
                .attr("x", -30)
                .attr("y", 6)
                .attr("dy", "1em")
                .style("text-anchor", "end")
                .style("font-size", "12px")
                .text(yLabel)

            # draw x axis
            svg.append("g")
            .attr("class", "x axis")
            .attr("transform", "translate("+(margin.left+5)+"," + (box_height + margin.top + 10) + ")")
            .call(xAxis)
            svg.selectAll(".x.axis .tick text")
                .attr("transform", "rotate(-90) translate(-10,-15)")
                .style("text-anchor", "end")

            if this.isRle
                svg.append('g')
                .attr("transform", "translate("+(margin.left-20)+",0)")
                .append('line')
                    .attr(
                        x1: 0
                        y1: y(0)
                        x2: width-margin.left-margin.right
                        y2: y(0)
                        stroke: '#000'
                        opacity: 0.5
                    )

    mounted: () ->
        this.calc_normalization()
#
#     get_svg = () ->
#         new_svg = d3.select(svg.node().cloneNode(true))
#         new_svg.attr('class','');
#         Print.copy_svg_style_deep(svg, new_svg)
#         {svg: new_svg.node(), width: svg.node().clientWidth, height: svg.node().clientHeight}
#
#
#     print_menu = (new Print(get_svg, "expression-boxplot")).menu()
#     d3.select(div.get(0)).on('contextmenu', d3.contextMenu(print_menu)) # attach menu to element
#
#     QC.overlay(div, () -> div.remove())
#
</script>
