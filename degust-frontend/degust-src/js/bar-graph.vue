<style scoped>
</style>

<template>
    <div>
    </div>
</template>

<script lang='coffee'>

class BarGraph
    constructor: (@opts) ->
        @opts.tot_width  ||= 200
        @opts.tot_height ||= 200
        @opts.margin_t ||= 20
        @opts.margin_l ||= 50
        @opts.margin_r ||= 10
        @opts.margin_b ||= 40
        @opts.ylabel ||= ''
        @opts.xlabel ||= ''
        @opts.title ||= ''
        @opts.title_y ?= -10
        @opts.fill ||= () -> 'steelblue'
        @opts.rotate_labels ||= false
        @opts.xordinal = true if !@opts.xordinal?

        @opts.stacked ?= false

        margin = {top: @opts.margin_t, right: @opts.margin_r, bottom: @opts.margin_b, left: @opts.margin_l}
        @width = @opts.tot_width - margin.left - margin.right
        @height = @opts.tot_height - margin.top - margin.bottom

        if @opts.xordinal
          @x = d3.scale.ordinal()
                 .rangeRoundBands([0, @width], .1)
        else
          @x = d3.scale.linear()
                 .range([0, @width])

        @y = d3.scale.linear()
               .range([@height, 0])

        @xAxis = d3.svg.axis()
                   .scale(@x)
                   .orient("bottom")
                   .tickSize(8,1)

        @yAxis = d3.svg.axis()
                   .scale(@y)
                   .orient("left")
                   .tickSize(8,1)

        @svg_real = d3.select(@opts.elem).append("svg")
                 .attr('class','bar-chart')
                 .attr("width", @width + margin.left + margin.right)
                 .attr("height", @height + margin.top + margin.bottom)
        @svg = @svg_real.append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")")
        @_make_menu(@opts.elem)

    _make_menu: (el) ->
        print_menu = (new Print(@svg_real, @opts.title)).menu()
        d3.select(el).on('contextmenu', d3.contextMenu(print_menu)) # attach menu to element

    draw: (data) ->
        if @opts.stacked
            data = d3.layout.stack().x((d) => d.lbl).y((d) => d.val)(data)
            @svg.selectAll("*").remove()
            max_y = d3.max(data, (d) -> d3.max d, (d) -> d.y0 + d.y)
            @x.domain(if @opts.xdomain? then @opts.xdomain else data.map((d) -> d.lbl))
            @y.domain([0, max_y])

        else
            @svg.selectAll("*").remove()
            @x.domain(if @opts.xdomain? then @opts.xdomain else data.map((d) -> d.lbl))
            @y.domain([0, d3.max(data, (d) -> debugger; d.val)])

        @svg.append("text")
             .attr('class', 'title')
             .attr("x", @width/2)
             .attr("y", @opts.title_y)
             .style("text-anchor", "middle")
             .text(@opts.title)

        @svg.append("g")
             .attr("class", "x axis")
             .attr("transform", "translate(0," + @height + ")")
             .call(@xAxis)
            .append("text")
             .attr('class', 'label')
             .attr("x", @width/2)
             .attr("y", @opts.margin_b-10)
             .style("text-anchor", "middle")
             .text(@opts.xlabel)

        if @opts.rotate_labels
          @svg.selectAll(".x.axis .tick text")
              .attr("transform", "rotate(-90) translate(-10,-15)")
              .style("text-anchor", "end")

        @svg.append("g")
             .attr("class", "y axis")
             .call(@yAxis)
           .append("text")
             .attr('class', 'label')
             .attr("transform", "rotate(-90)")
             .attr("x", -40)
             .attr("y", 20-@opts.margin_l)
             .style("text-anchor", "end")
             .text(@opts.ylabel)

        if @opts.stacked
            groups = @svg.selectAll("g.cost")
                .data(data)
                .enter().append("g")
                .attr("class", "cost")
                .attr("fill", (d, i) => ["#cddded", "#de0065"][i])

            groups.selectAll(".bar")
                .data((d) -> d)
                .enter().append("rect")
                .attr("class", "bar")
                .attr('x', (d) => @x(d.lbl))
                .attr('y', (d) => @y(d.y + d.y0))
                .attr('width', (d) => if d.width then @x(d.width) else @x.rangeBand())
                .attr("height", (d) => @height - @y(d.val))

        else
            @svg.selectAll(".bar")
                .data(data)
                .enter().append("rect")
                .attr("class", "bar")
                .attr("x", (d) => @x(d.lbl))
                .attr("width", (d) => if d.width then @x(d.width) else @x.rangeBand())
                .attr("y", (d) => @y(d.val))
                .attr("height", (d) => @height - @y(d.val))
                .attr("fill", (d) => @opts.fill(d))
                .on('click', (d) => if @opts.click? then @opts.click(d))

module.exports =
    name: 'bargraph'
    props:
        totWidth:
            default: 200
        totHeight:
            default: 200
        marginT:
            default: 20
        marginL:
            default: 50
        marginR:
            default: 10
        marginB:
            default: 40
        yLabel:
            default: ''
        xLabel:
            default: ''
        title:
            default: ''
        titleY: null
        fill:
            type: Function
            default: () -> 'steelblue'
        rotateLabels:
            default: false
        xOrdinal:
            default: true
        xDomain:
            default: null
        data:
            required: true
            type: Array
        stacked:
            default: null
    watch:
        data: () ->
            this.bargraph.draw(this.data)
    mounted: () ->
        this.bargraph = new BarGraph(
            elem: this.$el
            tot_width: this.totWidth
            tot_height: this.totHeight
            margin_t: this.marginT
            margin_l: this.marginL
            margin_r: this.marginR
            margin_b: this.marginB
            ylabel: this.yLabel
            xlabel: this.xLabel
            title_y: this.titleY
            title: this.title
            fill: this.fill
            rotate_labels: this.rotateLabels
            xordinal: this.xOrdinal
            xdomain: this.xDomain
            stacked: this.stacked
            click: (d) => this.$emit('click',d)
        )
        this.bargraph.draw(this.data)
</script>
