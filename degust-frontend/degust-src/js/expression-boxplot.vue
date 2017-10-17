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
    </div>
</template>

<script lang='coffee'>

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
        colour:
            type: Function
            default: d3.scale.category10()
    computed:
        cpm: () ->
            data = this.geneData
            cols = data.columns_by_type('count')
            cpm = cols.map((c,i) ->
                    norm_factor = data.get_total(c) / 1000000.0
                    vals = data.get_data().map((r) -> Math.log(0.5 + r[c.idx]/norm_factor)/Math.log(2))
                    {vals: vals, name:c.name, parent:c.parent, pos:i}
            )
            cpm
    mounted: () ->
        cpm = this.cpm
        margin = {top: 40, right: 50, bottom: 200, left: 50}
        width_box = 40
        width = width_box * cpm.length + margin.left + margin.right
        box_height = 400
        height = box_height + margin.top + margin.bottom

        chart = d3.box()
                  .whiskers(iqr(1.5))
                  .width(width_box/2)
                  .height(box_height)
                  .show_values(false)
                  .fill((c) => this.colour(c.parent))

        extent = d3.extent([].concat.apply([], cpm.map((r) -> d3.extent(r.vals))))
        chart.domain(extent)

        svg = d3.select(this.$el)
          .select("svg")
          .attr('height', height)
          .attr('width', width)
        svg.append("text")
             .attr('class', 'title')
             .attr("x", width/2)
             .attr("y", 15)
             .style("text-anchor", "middle")
             .text("Log CPM by library")

        # the x-axis
        x = d3.scale.ordinal()
               .domain( cpm.map((c) -> c.name) )
               .rangeRoundBands([0 , width_box * (cpm.length-1)], 0.7, 0.3)

        svg.selectAll("g.boxplot")
          .data(cpm)
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
              .attr("y", 6)
              .attr("dy", ".71em")
              .style("text-anchor", "end")
              .style("font-size", "16px")
              .text("log(cpm)")

        # draw x axis
        svg.append("g")
          .attr("class", "x axis")
          .attr("transform", "translate("+(margin.left+5)+"," + (box_height + margin.top + 10) + ")")
          .call(xAxis)
        svg.selectAll(".x.axis .tick text")
              .attr("transform", "rotate(-90) translate(-10,-15)")
              .style("text-anchor", "end")
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
