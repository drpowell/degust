class MAPlot
    constructor: (@opts) ->
        @opts.height ?= 300
        @opts.width ?= 600
        @opts.padding ?= 30


        @gDot = d3.select(@opts.elem).append('canvas')
        @gDot.attr("width", @opts.width)
             .attr("height", @opts.height)

        @svg = d3.select(@opts.elem).append('svg')
        @svg.attr("width", @opts.width)
            .attr("height", @opts.height)

        @gBrush = @svg.append('g')
        @gBrush.on('mousemove', () => @_mouse_move())
        @gBrush.on('mouseout',  () => @_mouse_out())

        @gHighlight = @svg.append('g')

        @tooltip = d3.select(@opts.elem).append("div")
                     .attr("class", "tooltip")
                     .style("opacity", 0)

        # Create a custom 'brush' event.  This will allow same API as par-coords
        @dispatch = d3.dispatch("brush","mouseover","mouseout")

        #@testInfo = d3.select(@opts.elem).append('div')

    update_data: (@data, fc_dim, ave_dim, @coloring, @info_cols, @fdr_col) ->
        if fc_dim.length!=1 || ave_dim.length!=1
            log_info("Only support 2 dimensions for ma-plot",fc_dim,ave_dim)
            return

        @svg.select("g.brush").remove()
        @svg.selectAll(".axis").remove()

        @m_dim = m_dim = (d) -> d[fc_dim[0].idx]
        @a_dim = a_dim = (d) -> d[ave_dim[0].idx]

        @xScale = xScale = d3.scale.linear()
                     .domain(d3.extent(@data, (d) -> a_dim(d)).map((x) -> x*1.05))
                     .range([@opts.padding, @opts.width-@opts.padding]);
        @yScale = yScale = d3.scale.linear()
                     .domain(d3.extent(@data, (d) -> m_dim(d)).map((x) -> x*1.05))
                     .range([@opts.height-@opts.padding, @opts.padding]);

        xAxis = d3.svg.axis()
                  .scale(xScale)
                  .orient("bottom")
        yAxis = d3.svg.axis()
                  .scale(yScale)
                  .orient("left")
                  .ticks(5)

        @mybrush = d3.svg.brush()
          .x(xScale)
          .y(yScale)
          .clamp([false,false])
          .on("brush",  () => @_brushed())
        @gBrush.call(@mybrush)

        @_draw_dots()

        @svg.append("g")
            .attr("class", "axis")
            .attr("transform", "translate(0," + yScale(0) + ")")
            .call(xAxis)
           .append("text")
            .attr("x", xScale.range()[1])
            .attr("y", -6)
            .style("text-anchor", "end")
            .text("Avg log expr")

        @svg.append("g")
            .attr("class", "axis")
            .attr("transform", "translate(" + @opts.padding + ",0)")
            .call(yAxis)
           .append("text")
            .attr("transform", "rotate(-90)")
            .attr("x", -5)
            .attr("y", 5)
            .attr("dy", ".71em")
            .style("text-anchor", "end")
            .text("logFC")

    _draw_dots: () ->
        ctx = @gDot[0][0].getContext("2d")
        ctx.clearRect(0,0,@opts.width, @opts.height)
        i=@data.length
        while(i--)
            do (i) =>
                d = @data[i]
                if @opts.filter(d)
                    ctx.fillStyle = @coloring(d)
                    ctx.globalAlpha = 0.7
                    ctx.beginPath()
                    ctx.arc(@xScale(@a_dim(d)), @yScale(@m_dim(d)), 3, 0, Math.PI*2)
                    ctx.fill()
                    #ctx.strokeStyle="#000000"
                    #ctx.stroke()

    # Event handler for mouse-move.  Schedule a tooltip display (this is a potentially expensive operation)
    _mouse_move: () ->
        loc = d3.mouse(@gDot[0][0])
        @_hide_info()
        scheduler.schedule('maplot.tooltip', (() => @_handle_tooltip(loc)), 20)

    # Event handler for mouse-out.  Hide tooltip, and kill any pending tip
    _mouse_out: () ->
        @_hide_info()
        scheduler.schedule('maplot.tooltip', () => )

    # Lookup point for tooltip and display (or hide).
    # This scans all data points, so can be expensive.  It is acceptable on my machine,
    # it might be worth considering d3.geom.quadtree if it needs to be faster
    _handle_tooltip: (loc) ->
        [x,y] = loc

        sz=3
        # Note swapped 'y' in extent (because yScale is a -ve transform)
        ex = [[@xScale.invert(x-sz), @yScale.invert(y+sz)],
              [@xScale.invert(x+sz), @yScale.invert(y-sz)]]

        m = @_in_extent(ex)

        if m.length>0
            @_show_info(loc, m)
            @dispatch.mouseover(m)
        else
            @_hide_info()
            @dispatch.mouseout()


    # Display and fill in the tooltip
    _show_info: (loc, rows) ->
        fmt  = (val) -> val.toFixed(2)
        fmt2 = (val) -> if val<0.01 then val.toExponential(2) else val.toFixed(2)

        @tooltip.transition().duration(200)
                .style("opacity", 0.8)
        info="<table>"
        row=rows[0]
        @info_cols.forEach((c) ->
            info += "<tr><td><b>#{c.name}</b>:<td>#{row[c.idx]}"
        )
        info += "<tr><td><b>A</b>:<td>#{fmt @a_dim(row)}"
        info += "<tr><td><b>M</b>:<td>#{fmt @m_dim(row)}"
        info += "<tr><td><b>FDR</b>:<td>#{fmt2 row[@fdr_col]}"
        info += "</table>"
        if rows.length>1
            info += "(And #{rows.length-1} other#{if rows.length>2 then 's' else ''})"

        @tooltip.html(info)
                .style("left", (loc[0] + 10) + "px")
                .style("top",  (loc[1] + 15) + "px")

    # Hide tooltip
    _hide_info: () ->
        @tooltip.style("opacity", 0)

    _brushed: () ->
        sel = @_selected()
        #console.log 'brushed', sel
        @dispatch.brush(sel)

    _in_extent: (ex) ->
        @data.filter((d) =>
            y = @m_dim(d)
            x = @a_dim(d)
            @opts.filter(d) && x>=ex[0][0] && x<=ex[1][0] && y>=ex[0][1] && y<=ex[1][1]
        )

    _selected: () ->
        if @mybrush.empty()
            @data.filter((d) => @opts.filter(d))
        else
            @_in_extent(@mybrush.extent())

    highlight: (rows) ->
        hi = @gHighlight.selectAll(".highlight")
                 .data(rows, (d) -> d.id)
        hi.exit().remove()
        hi.enter().insert("circle")
            .attr("class", "highlight")
            .attr("opacity", 1)
            .style("fill-opacity", 0)
            .style("stroke", "black")
            .style("stroke-width", 3)

        hi.attr("r", 15)
          .attr("cx", (d) => @xScale(@a_dim(d)))
          .attr("cy", (d) => @yScale(@m_dim(d)))
          .transition().duration(500)
          .attr("r", 7);

    unhighlight: () ->
        @svg.selectAll(".highlight").remove()

    on: (t,func) ->
        @dispatch.on(t, func)

    brush: () ->
        @_draw_dots()
        @_brushed()

    brush_extent: (ex) ->
        if ex?
            @mybrush.extent()
            @mybrush(@svg.select(".brush"))
            @mybrush.event(@svg.select(".brush"))
        else
            @mybrush.extent()


window.MAPlot = MAPlot
