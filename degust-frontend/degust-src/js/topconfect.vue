<style scoped>
.outer {
    height: 400px;
    overflow-y: auto;
}

.outer >>> svg {
}

.outer >>> .axis line, .outer >>> .axis path {
  fill: none;
  stroke: #222;
  shape-rendering: crispEdges;
}

.outer >>> .axis text {
    font-family: sans-serif;
    font-size: 9px;
}

.outer >>> .grid line {
  stroke: #ddd;
}

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
        <div class='outer'>
            <svg>
            </svg>
        </div>
        <div class='tooltip' v-if='hover' :style="tooltipStyle">
            <table>
                <tr v-for='c in infoCols'>
                    <td><b>{{c.name}}:</b></td>
                    <td>{{hover.gene[c.idx]}}</td>
                </tr>
                <tr><td><b>Ave Expr:</b></td><td>{{fmt(hover.confect.AveExpr)}}</td></tr>
                <tr><td><b>confect:</b></td><td>{{fmt(hover.confect.confect)}}</td></tr>
                <tr><td><b>effect:</b></td><td>{{fmt(hover.confect.effect)}}</td></tr>
                <tr><td><b>FDR:</b></td><td>{{fmt2(hover.gene['adj.P.Val'])}}</td></tr>
            </table>
            <div v-if='hover.length>1'>
                And {{hover.length-1}} other{{hover.length>2 ? 's' : ''}}
            </div>
        </div>
    </div>
</template>

<script lang='coffee'>


module.exports =
    name: 'topconfect'

    props:
        backend: null
        sel_conditions: null
        sel_contrast: null
        gene_data: null
        name:
            default: "topconfect"
    data: () ->
        width: 1
        height: 1
        pxPerLine: 20
        margin:
            t: 10
            r: 100
            b: 20
            l: 10
        axisColour: '#555'
        hover: null
        tooltipLoc: [0,0]
        infoCols: []

    computed:
        tooltipStyle: () ->
            {left: (this.tooltipLoc[0]+40)+'px', top: (this.tooltipLoc[1]+35)+'px'}

    methods:
        mk_axes: (xScale) ->
            xAxis = d3.svg.axis()
                .scale(xScale)
                .orient("bottom")
                .ticks(7)
            d3.select("g.axis", this.$el)
                .append("rect")
                .attr("x", @margin.l)
                .attr("y", @margin.t)
                .attr("width", @width-@margin.l-@margin.r)
                .attr("height", @height-@margin.t-@margin.b)
                .attr('fill-opacity', 0)
                .attr('stroke', @axisColour)
            d3.select(this.$el)
                .select("g.axis")
                .append('g')
                .attr("transform", "translate(0,#{@height-@margin.b})")
                .call(xAxis)
            d3.select(this.$el)       # Vertical grid
                .select("g.axis")
                .append("g")
                .attr("class","grid")
                .attr("transform", "translate(0," + @margin.t + ")")
                .call(xAxis.tickSize(@height-@margin.b-@margin.t).tickFormat(""))
                .selectAll('line')
            d3.select(this.$el)        # Darker vertical line at 0
                .select("g.axis")
                .append("line")
                .attr("x1", xScale(0))
                .attr("x2", xScale(0))
                .attr("y1", @margin.t)
                .attr("y2", @height-@margin.b)
                .attr('stroke', @axisColour)

        process_confect_data: (data) ->
            #data = data[0...200]
            data.forEach((r) ->
                # Make columns numeric
                for col in ['confect','effect','AveExpr', 'index']
                    r[col] = +r[col]
            )
            #data.sort((a,b) -> Math.abs(b.effect) - Math.abs(a.effect))
            data.sort((a,b) -> Math.abs(b.confect) - Math.abs(a.confect))
            @infoCols = @gene_data.columns_by_type('info')

            @init_chart(data)

            @xrange = xrange = [@margin.l, @width-@margin.r]
            # the axes
            @xScale = d3.scale.linear()
                .domain( d3.extent(data.map((r) -> r.effect) ) )
                .range(xrange)
            @yScale = d3.scale.linear()
                .domain( [0, data.length] )
                .range([@margin.t + @pxPerLine/2, data.length * @pxPerLine])
            @sc = d3.scale.linear()
                .domain( d3.extent(data.map((r) -> r.effect) ) )
                .range([1,10])
            @mk_axes(@xScale)

            @_mayRender(0, data)

        _mayRender: (pos, data) ->
            top_idx = Math.floor((pos+@margin.t)/@pxPerLine)
            num_show = Math.floor((@height-@margin.t-@margin.b)/@pxPerLine)-1
            idxrows = [top_idx .. top_idx+num_show]
            genes = d3.select(this.$el)
                      .select("g.genes")
                      .selectAll('g.row')
                      .data(idxrows, (d) -> d)
            genes.exit().remove()
            row = genes.enter().append("g")
                               .attr("class", "row")
            row.append('line')
                 .attr('x1', () => @xrange[1])
                 .attr('y1', (idx) => @yScale(idx))
                 .attr('x2', () => @xrange[1]+3)
                 .attr('y2', (idx) => @yScale(idx))
                 .attr('stroke', @axisColour)
            row.append('line')
                 .attr('x1', () => @xrange[0])
                 .attr('y1', (idx) => @yScale(idx))
                 .attr('x2', () => @xrange[1])
                 .attr('y2', (idx) => @yScale(idx))
                 .attr('stroke', '#ddd')
            row.append('circle')
                 .attr('cx', (idx) => @xScale(data[idx].effect))
                 .attr('cy', (idx) => @yScale(idx))
                 .attr('r', (idx) => @sc(data[idx].AveExpr))
                 .attr('fill', 'blue')
            row.append('line')
                 .attr('x1', (idx) => if data[idx].confect==0 then @xrange[0] else @xScale(data[idx].confect))
                 .attr('y1', (idx) => @yScale(idx))
                 .attr('x2', (idx) => if data[idx].confect<0 then @xrange[0] else @xrange[1])
                 .attr('y2', (idx) => @yScale(idx))
                 .attr('stroke', 'blue')
                 .attr('stroke-width', 2)
            row.append('text')
                 .attr('x', (idx) => @xrange[1]+5)
                 .attr('y', (idx) => @yScale(idx))
                 .attr('alignment-baseline', 'middle')
                 .text((idx) =>
                    gene = @gene_data.row_by_id(data[idx].index-1)
                    gene[@infoCols[0].idx]
                 )
            row.on('mouseover', (idx) =>
                    gene = @gene_data.row_by_id(data[idx].index-1)
                    loc = d3.mouse(this.$el)             # Location in element
                    @show_info(data[idx], gene, loc)
                 )
            row.on('mouseout', () => @hide_info())


        init_chart: (data) ->
            @width = 600
            @height = 400

            d3.select(this.$el).select('svg').selectAll("*").remove()

            svg = d3.select(this.$el)
                    .select("svg")
                    .attr('viewBox', "0 0 800 #{data.length * @pxPerLine}")
            axis = svg.append("g").attr('class', 'axis')
            svg.append("g").attr('class','genes')

            d3.select(".outer", this.$el)
              .on('scroll', (ev) =>
                # Convert from div scroll pixels, to the viewBox coords of svg
                h = svg.node().clientHeight
                pos = data.length * @pxPerLine / h * d3.event.target.scrollTop
                axis.attr("transform","translate(0,#{pos})")
                @_mayRender(pos, data)
              )

        show_info: (confect, gene,loc) ->
            this.hover={confect: confect, gene:gene}
            this.tooltipLoc = loc
            this.$emit('hover-start',[gene],loc)
        hide_info: () ->
            this.hover=null
            this.$emit('hover-end')
        fmt: (val) -> val.toFixed(2)
        fmt2: (val) -> if val<0.01 then val.toExponential(2) else val.toFixed(2)


    mounted: () ->

        p = this.backend.do_request_data('topconfect', this.sel_conditions, this.sel_contrast)
        p.then(([data,extra]) =>
            @process_confect_data(data)
        )

</script>
