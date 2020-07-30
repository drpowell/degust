<style scoped>
.outer {
    height: 400px;
    overflow-y: auto;
    margin-bottom: 20px;
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
        <div>
            <small>
                This topconfects feature is <b>experimental</b>.  See the <a target=_blank href='https://genomebiology.biomedcentral.com/articles/10.1186/s13059-019-1674-7'>paper</a> for details
            </small>
        </div>
        <div class='outer'>
            <svg>
            </svg>
        </div>
        <div class='tooltip' v-if='hover' :style="tooltipStyle">
            <table>
                <tr v-for='c in infoCols'>
                    <td><b>{{c.name}}:</b></td>
                    <td>{{hover[c.idx]}}</td>
                </tr>
                <tr><td><b>Ave Expr: </b></td><td>{{fmt(hover.AveExpr)}}</td></tr>
                <tr><td><b>confect: </b></td><td>{{fmt(hover.confect)}}</td></tr>
                <tr><td><b>effect: </b></td><td>{{fmt(hover[this.logfcCol.idx])}}</td></tr>
                <tr><td><b>FDR: </b></td><td>{{fmt2(hover['adj.P.Val'])}}</td></tr>
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
        gene_data: null
        gene_name_column: null
        data: null
        logfcCol : null
        name:
            default: "topconfect"
        highlight: null
        filter: null
        filterChanged: null
    data: () ->
        width: 1
        height: 1
        pxPerLine: 20
        margin:
            t: 0
            r: 100
            b: 20
            l: 10
        axisColour: '#555'
        num_rows_show: 1
        hover: null
        tooltipLoc: [0,0]
        infoCols: []
        id_to_row: []      # Caches the gene.id integer, to the row we are using.  Used for quick-scroll to highlight

    computed:
        tooltipStyle: () ->
            {left: (this.tooltipLoc[0]+40)+'px', top: (this.tooltipLoc[1]+35)+'px'}

    watch:
        filterChanged: () ->
            this.init()
        data: () ->
            this.init()
        highlight: () ->
            if this.highlight? && this.highlight.length>0
                id = this.highlight[0].id
                top_idx = this.id_to_row[id]

                h = d3.select('svg',this.$el).node().clientHeight
                pos = top_idx*@pxPerLine - @margin.t
                d3.select('.outer',this.$el).node().scrollTo(
                      top: pos * h / (@id_to_row.length * @pxPerLine),
                      left: 0,
                      behavior: 'smooth'
                )

    methods:
        row_info: (row) ->
            if this.gene_name_column && row[this.gene_name_column] != undefined
                row[this.gene_name_column]
            else
                if @infoCols && @infoCols.length>0
                    row[@infoCols[0].idx]
                else
                    ""

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

        init: () ->
            data_all = @gene_data.get_data()[..]      # Take a show copy of the gene data array.  Sort by confect
            data  = data_all.filter((d) => @filter(d))
            this.$emit('brush', data, true)

            data.sort((a,b) -> Math.abs(b.confect) - Math.abs(a.confect))

            @id_to_row = []
            for gene, row_idx in data
                @id_to_row[gene.id] = row_idx

            @infoCols = @gene_data.columns_by_type('info')

            @_init_chart(data)
            effect = this.logfcCol.idx

            @xrange = [@margin.l, @width-@margin.r]
            # the axes
            xMax = d3.max(data_all.map((r) -> Math.abs(r[effect])))
            @xScale = d3.scale.linear()
                .domain([-xMax, xMax])
                .range(@xrange)
            @yScale = d3.scale.linear()
                .domain( [0, data.length] )
                .range([@margin.t + @pxPerLine/2, @margin.t + data.length * @pxPerLine + @pxPerLine/2])
            @sc = d3.scale.linear()
                .domain(d3.extent( data_all.map((r) -> r.AveExpr).concat([0])))
                .range([1,15])
            @mk_axes(@xScale)

            @_mayRender(0, data)

        _mayRender: (top_idx, data) ->
            if data.length==0
                return
            last_idx = top_idx + @num_rows_show
            if last_idx>data.length-1
                last_idx = data.length-1
            idxrows = [top_idx .. last_idx]

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
                 .attr('cx', (idx) => @xScale(data[idx][this.logfcCol.idx]))
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
                 .text((idx) => this.row_info(data[idx]))
            row.on('mouseover', (idx) =>
                    loc = d3.mouse(this.$el)             # Location in element
                    @show_info(data[idx], loc)
                 )
            row.on('mouseout', () => @hide_info())


        _init_chart: (data) ->
            @width = 800
            @height = 450
            @num_rows_show = Math.floor((@height-@margin.t-@margin.b)/@pxPerLine)-1

            d3.select(this.$el).select('svg').selectAll("*").remove()

            boxHeight = Math.max(data.length, @num_rows_show+2) * @pxPerLine

            svg = d3.select(this.$el)
                    .select("svg")
                    .attr('viewBox', "0 0 #{@width} #{boxHeight}")
            axis = svg.append("g").attr('class', 'axis')
            svg.append("g").attr('class','genes')

            d3.select(".outer", this.$el)
              .on('scroll', (ev) =>
                # Convert from div scroll pixels, to the viewBox coords of svg
                h = svg.node().clientHeight
                pos = data.length * @pxPerLine / h * d3.event.target.scrollTop
                top_idx = Math.floor((pos+@margin.t)/@pxPerLine)

                axis.attr("transform","translate(0,#{pos})")
                @_mayRender(top_idx, data)
              )

        show_info: (gene,loc) ->
            this.hover=gene
            this.tooltipLoc = loc
            this.$emit('hover-start',[gene],loc)
        hide_info: () ->
            this.hover=null
            this.$emit('hover-end')
        fmt: (val) -> val.toFixed(2)
        fmt2: (val) -> if val<0.01 then val.toExponential(2) else val.toFixed(2)

    mounted: () ->
        this.init()

</script>
