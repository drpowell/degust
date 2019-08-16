class GeneExpression
    constructor: (@opts) ->
        @width = @opts.width || d3.select(@opts.elem).node().clientWidth
        @height = 300
        @margin_l = 80
        @margin_b = 120
        @margin_t = 30
        @plot_height = @height - @margin_t - @margin_b
        @plot_width = @width - @margin_l
        @colour = @opts.colour || d3.scale.category10()

        @x = d3.scale.ordinal()
              .rangeRoundBands([0, @plot_width], .1)
        @y = d3.scale.linear()
               .range([@plot_height, 0])

        @xAxis = d3.svg.axis()
                   .scale(@x)
                   .orient("bottom")
                   .tickSize(8,1)

        @yAxis = d3.svg.axis()
                   .scale(@y)
                   .orient("left")
                   .tickSize(8,1)

        @svg = d3.select(@opts.elem).append("svg")
                 .attr('class','strip-chart')
                 .attr("width", @width)
                 .attr("height", @height)
                .append('g')
                 .attr("transform", "translate(#{@margin_l}, #{@margin_t})")

        @tooltip = d3.select(@opts.elem).append("div")
                     .attr("class", "tooltip")
                     .style("opacity", 0)

        @jitter_cache = {}
        @show_cpm = false
        @_make_menu(@opts.elem)

    # Return a copy of the SVG with styles attached from the stylesheet
    _get_svg: () ->
        svg = d3.select(@opts.elem).select("svg")
        new_svg = d3.select(svg.node().cloneNode(true))
        new_svg.attr('class','');
        Print.copy_svg_style_deep(svg, new_svg)
        {svg: new_svg.node(), width: svg.node().clientWidth, height: svg.node().clientHeight}

    _make_menu: (el) ->
        print_menu = (new Print((() => @_get_svg()), "Gene expression")).menu()
        menu = [
                title: () => (if @show_cpm then "Plot counts" else "Plot CPM")
                action: () =>
                    @show_cpm = !@show_cpm
                    @update()
        ]
        d3.select(el).on('contextmenu', d3.contextMenu(menu.concat(print_menu))) # attach menu to element

    select: (@data, @rows) ->
        @update()

    update: () ->
        @svg.selectAll("*").remove()

        row = @rows[0]  # Just use first for now.  TODO, make others selectable
        @columns = cols = @data.columns_by_type('count')
        vals = cols.map((c) =>
            norm_factor = @data.get_total(c) / 1000000.0
            # {lbl: c.name, parent: c.parent, val: Math.log(0.5 + row[c.idx]/norm_factor)/Math.log(2)}
            val = if @show_cpm then row[c.idx]/norm_factor else row[c.idx]
            {lbl: c.name, parent: c.parent, val: val}
        )
        info_cols = @data.columns_by_type('info')

        @x.domain(vals.map((d) -> d.parent ))
        @y.domain([0, d3.max(vals, (d) -> d.val)])

        @svg.append("text")
             .attr('class', 'title')
             .attr("x", @plot_width/2)
             .attr("y", -(@margin_t/2))
             .style("text-anchor", "middle")
             .text(row[info_cols[0].idx])

        @svg.append("g")
             .attr("class", "x axis")
             .attr("transform", "translate(0,#{@height-@margin_b-@margin_t})")
             .call(@xAxis)

        @svg.selectAll(".x.axis .tick text")
              .attr("transform", "rotate(-90) translate(-10,-15)")
              .style("text-anchor", "end")

        @svg.append("g")
             .attr("class", "y axis")
             .call(@yAxis)
           .append("text")
             .attr('class', 'label')
             .attr("transform", "rotate(-90)")
             .attr("x", 0)
             .attr("y", 10)
             .style("text-anchor", "end")
             .text(if @show_cpm then "CPM" else "Counts")

        pts = @svg.selectAll(".pts")
            .data(vals)
            .enter().append("circle")
              .attr("class", "circle")
              .attr("r", 4)
              .attr("fill", (d) => @colour(d.parent))
              .attr("cx", (d) => @x(d.parent)+@x.rangeBand()/2 + @jitter(d))
              .attr("cy", (d) => @y(d.val))

        pts.on('mouseover', (d) => @_show_tooltip(d))
        pts.on('mouseout', () => @_hide_tooltip())

    jitter: (d) ->
        @jitter_cache[d.lbl] ?= Math.random()*8 - 4

    _hide_tooltip: () ->
        @tooltip.style("opacity", 0)

    _show_tooltip: (row) ->
        if (!row)
            @_hide_tooltip()
            return

        loc = [d3.event.pageX, d3.event.pageY]

        if @show_cpm
            fmt = (val) -> val.toFixed(2)
        else
            fmt = (val) -> val
        #fmt2 = (val) -> if val<0.01 then val.toExponential(2) else val.toFixed(2)

        @tooltip.transition().duration(200)
                .style("opacity", 0.8)
        info="<table>"
        info += "<tr><td><b>#{row.lbl}</b>:<td>#{fmt(row.val)}"
        info += "</table>"

        @tooltip.html(info)
                .style("left", (loc[0] - 60) + "px")
                .style("top",  (loc[1] + 15) + "px")




window.GeneExpression = GeneExpression
