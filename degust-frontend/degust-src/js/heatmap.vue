<style scoped>

.heatmap >>> .extent {
  fill: #990;
  fill-opacity: .2;
  stroke: #000;
}

.heatmap >>> .info {
  font-size: 10px;
}

.heatmap >>> .legend {
  font-size: 10px;
}

.heatmap >>> .legend path {
  display: none;
}

.heatmap >>> .legend line {
  stroke: #000;
  shape-rendering: crispEdges;
}

.heatmap >>> #arrow, .heatmap >>> .arrow {
    stroke-width:2;
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
        <div class='heatmap' v-once ref='hmap' id='heatmap'></div>
        <div class='tooltip' v-if='Object.keys(hover).length > 0 && interactive' :style='tooltipStyle'>
            <table>
                <tr v-for='c in infoCols'>
                    <td><b>{{c.name}}:</b></td>
                    <td>{{hover[c.idx]}}</td>
                </tr>
                <tr><td><b>Ave Expr:</b></td><td>{{fmt(hover[avgCol.idx])}}</td></tr>
                <tr><td><b>FDR:</b></td><td>{{fmt2(hover[fdrCol.idx])}}</td></tr>
            </table>
            <div v-if='hover.length>1'>
                And {{hover.length-1}} other{{hover.length>2 ? 's' : ''}}
            </div>
        </div>
    </div>
</template>

<script lang='coffee'>

viridis = require('./lib/scale-color-perceptual/hex/viridis.json')
inferno = require('./lib/scale-color-perceptual/hex/inferno.json')
magma   = require('./lib/scale-color-perceptual/hex/magma.json')
plasma  = require('./lib/scale-color-perceptual/hex/plasma.json')

{ calc_extent } = require('./normalize.coffee')

# Calculate an ordering for the genes.
# This uses a greedy N^2 algorithm to find the next closest data point on each iteration.
# Seems to do a decent job.
# The optimal solution is actually a travelling salesman problem.  I'm happy
# for better heuristics than this.  I did try an MDS of the data points and order
# those by the first dimension, but that did not give a nice heatmap.
# NOTE: this is intended to be used in a web-worker so has no external dependencies
calc_order = (e) ->
    [data, columns] = e.data

    t1 = new Date()

    if !data?
        self.postMessage({error: "Data missing"})
        return

    if !columns?
        self.postMessage({error: "Columns missing"})
        return

    if data? && data.length==0
        self.postMessage({done: []})
        return

    # Distance calc for 2 genes. (for clustering)
    dist = (r1,r2) ->
        s = 0
        for c in columns
            v = r1[c.idx]-r2[c.idx]
            s += v*v
            #s = Math.max(s,v)
        s

    # Calculate the most extreme point.  First calculate the "centre" of all the data-points
    # Then find the data-point most distant from it.  Will be used to start the clustering
    # Seems like a reasonable heuristic
    calc_extreme_point = () ->
        centroid = []
        tot = 0
        data.forEach((r) =>
            columns.map((c) ->
                centroid[c.idx]||=0
                centroid[c.idx] += r[c.idx])
            tot+=1)
        for k,v of centroid
            centroid[k] = v/tot
        max_i=0
        max_d=0
        for i in [0 .. data.length-1]
            d = dist(centroid, data[i])
            if d>max_d
                max_d=d
                max_i=i
        return max_i

    used = {}
    order = [calc_extreme_point()]
    used[order[0]] = true

    # Greedy clustering.  Find closest data-point and append
    message_after = 0
    while order.length < data.length
        if (message_after++)>=50
            message_after = 0
            postMessage({upto: order.length})
        row = data[order[order.length-1]]
        best_i = best_d = null
        for i in [0 .. data.length-1]
            continue if used[i]
            r = data[i]
            d = dist(row,r)
            if !best_d or d<best_d
                best_d = d
                best_i = i
        order.push(best_i)
        used[best_i] = true

    # Done.
    order_ids = order.map((i) => data[i].id)
    postMessage({done: order_ids, took: (new Date())-t1})
    close()

class Heatmap
    constructor: (@opts) ->
        @opts.h_pad ?= 20
        @opts.h ?= 20
        @opts.label_width ?= 120
        @opts.legend_height ?= 50
        @opts.geneOrder ?= true
        @opts.enablecontextmenu ?= true
        @opts.showlegend ?= true
        @opts.twocolor ?= false
        @opts.interactive ?= true

        @opts.width ?= d3.select(@opts.elem).node().clientWidth - 20;

        @svg = d3.select(@opts.elem).append('svg')
        @svg.append('g').attr("class", "labels")
        g = @svg.append('g').attr("transform", "translate(#{@opts.label_width},0)")
        g.append('g').attr("class", "genes")
        g.append('g').attr("class", "highlight")
        @svg.attr("width", "100%").attr("height", 100)

        @mk_highlight()

        @info = @svg.append('text')
                    .attr("class", "info")
                    .attr("x", @opts.width-200)
                    .attr("y", 10)

        @legend = @svg.append('g').attr('class',"legend")

        @dispatch = d3.dispatch("mouseover","mouseout","show_replicates","hide")

        if @opts.twocolor
            @get_color_scale = @_color_two
        else
            @get_color_scale = @_color_red_blue;

        # Create a single wrapper for later use
        @worker = new WorkerWrapper(calc_order, (d) => @_worker_callback(d))
        @_enabled = true
        @columns_changed = false
        if @opts.enablecontextmenu
            @_make_menu(@opts.elem)

    mk_highlight: () ->
        @svg.append("defs")
            .append("marker")
                .attr({
                    "id":"arrow",
                    "viewBox":"0 -5 10 10",
                    "refX":5,
                    "refY":0,
                    "markerWidth":4,
                    "markerHeight":4,
                    "orient":"auto"
                })
                .append("path")
                    .attr("d", "M0,-5L10,0L0,5")
                    .attr("class","arrowHead");

    resize: () ->
        if !@_enabled
            return
        @opts.width = d3.max([0, d3.select(@opts.elem).node().clientWidth - 20])
        @info.attr("x", @opts.width-200)
        @_redraw_all();

    # Enable/disable the heatmap.  When disabled it is hidden and does not update
    enabled: (enabled) ->
        if enabled?
            @_enabled = enabled
            $(@opts.elem).toggle(enabled)
            if (@opts.show_elem?)
                $(@opts.show_elem).toggle(!enabled)
        else
            @_enabled

    # Return a copy of the SVG with styles attached from the stylesheet
    _get_svg: () ->
        new_svg = d3.select(@svg.node().cloneNode(true))
        new_svg.attr('class','');
        Print.copy_svg_style_deep(@svg, new_svg)
        {svg: new_svg.node(), width: @svg.node().clientWidth, height: @svg.node().clientHeight}

    _make_menu: (el) ->
        print_menu = (new Print((() => @_get_svg()), "heatmap")).menu()
        menu = [
                title: 'Hide heatmap'
                action: () => @dispatch.hide()
            ,
                # TODO these options should come from the parent
                title: () => (if @opts.show_replicates then "Hide" else "Show")+" replicates"
                action: () => @dispatch.show_replicates(!@opts.show_replicates)
            ,
                divider: true
            ,
                title: 'Colour scheme'
            ,
                title: 'Red/white/blue'
                action: (elm, d, i) =>
                    @get_color_scale = @_color_red_blue;
                    @_redraw_all();
            ,
                title: 'Red/black/green'
                action: (elm, d, i) =>
                    @get_color_scale = @_color_red_green;
                    @_redraw_all();
            ,
                title: 'Viridis'
                action: (elm, d, i) =>
                    @get_color_scale = @_color_viridis(viridis);
                    @_redraw_all();
            ,
                title: 'Inferno',
                action: (elm, d, i) =>
                    @get_color_scale = @_color_viridis(inferno);
                    @_redraw_all();
            ,
                title: 'Magma',
                action: (elm, d, i) =>
                    @get_color_scale = @_color_viridis(magma);
                    @_redraw_all();
            ,
                title: 'Plasma',
                action: (elm, d, i) =>
                    @get_color_scale = @_color_viridis(plasma);
                    @_redraw_all();
            ,
                divider: true
        ]
        d3.select(el).on('contextmenu', d3.contextMenu(menu.concat(print_menu))) # attach menu to element

    _color_two : () ->
        d3.scale.ordinal()
                 .domain([0, 1])
                 .range(["#cddded", "#de0065"]);

    _color_red_blue : () ->
        d3.scale.linear()
                 .domain([-@max, 0, @max])
                 .range(["blue", "white", "red"]);

    _color_red_green : () ->
        d3.scale.linear()
                 .domain([-@max/2, 0, @max/2])
                 .range(["green", "black", "red"]);

    _color_viridis: (scale) ->
        () ->
          d3.scale.quantize()
             .domain([-@max, @max])
             .range(scale);

    _redraw_all : () ->
        @_draw_columns()
        if !@_is_thinking
            @_render_heatmap()


    _make_legend: () ->
        @colorScale = @get_color_scale()
        @legend.selectAll("*").remove()

        @legend.append('text')
            .attr("x", -10)
            .attr("y", 20)
            .attr("text-anchor", "end")
            .text("Heatmap log-fold-change ")

        width = 100
        @legend.attr("transform", "translate(#{@opts.width-width-20}, #{@height - @opts.legend_height})")

        steps = width
        stepToVal = d3.scale.linear().domain([0, steps-1]).range([-@max, @max])
        vals = (v for v in [0 ... steps])

        g = @legend.append('g')

        rects = g.selectAll('rect')
                    .data(vals)
        rects.enter().append("rect")
                    .attr("x", (v) -> v*1.0*width/steps)
                    .attr("height", 20)
                    .attr("width", 1.0*width/steps)
                    .style("fill", (v) => @colorScale(stepToVal(v)))

        sc = d3.scale.linear().domain([-@max,@max]).range([0,width])
        axis = d3.svg.axis()
                .scale(sc)
                .orient("bottom")
                .ticks(7)
                .tickSize(5)
        # Draw the ticks and rotate labels by 90%
        g.append('g')
        .attr('transform', "translate(0, 20)")
        .call(axis)
        .selectAll("text")
            .style("text-anchor", "end")
            .attr("dx", "-.8em")
            .attr("dy", "-0.4em")
            .attr("transform", "rotate(-90)");

    set_order: (@order) ->
        # Nothing

    _show_calc_info: (str) ->
        @info.text(str)

    _worker_callback: (d) ->
        if d.error?
            log_error("Worker error : #{d.error}")
        if d.upto?
            @_show_calc_info("Clustered #{d.upto} of #{@data.length}")
        if d.done?
            @order = d.done
            @_render_heatmap()
            @_show_calc_info("")
        if d.took?
            log_debug("calc_order: took=#{d.took}ms for #{@data.length} points")

    # Calculate the order of genes for the heatmap.  This uses the 'calc_order' function
    # from above, wrapped in a web-worker
    _calc_order: () ->
        if @opts.geneOrder
            @worker.start([@data, @columns.map((c) -> {idx: c.idx})])
        else
            @order = @data.map((el) -> el.id)
            @_render_heatmap()
            @_show_calc_info()

    _thinking: (bool) ->
        @_is_thinking = bool
        @svg.select("g.genes").attr('opacity',if bool then 0.4 else 1)

    # Update which rows are displayed (set in update_columns())
    schedule_update: (rows) ->
        @rows=rows if rows
        return if !@rows? || !@columns? || !@_enabled

        scheduler.schedule('heatmap.render', () => )

        # Pull out of @data_all, just the rows we want
        @data = @rows.map((r) => @data_all[r.id])
        # Recalc @max? and redraw legend?

        @_thinking(true)
        @_calc_order()

    # update_columns(data, columns,extent)
    #   columns - The DGE condition columns
    #   extent - the total range of all columns
    update_columns: (@data_object, to_show, @columns, centre) ->
        @height = @opts.legend_height + @opts.h_pad + (@opts.h * @columns.length);
        @svg.attr("width", @opts.width)
            .attr("height", @height)

        @data_all = {}   # Indexed by row.id
        @data_object.get_data().forEach((r) =>
            @data_all[r.id] = if centre then @_centre(r) else r
        )
        extent = calc_extent(d3.values(@data_all), @columns)
        @max = d3.max(extent.map(Math.abs))
        @_draw_columns()
        @schedule_update(to_show)

    # Given the row, copy over @columns, but centered
    _centre: (row) ->
        m = d3.mean(@columns.map((c) -> row[c.idx]))
        res = {}
        res.id = row.id
        @columns.map((c) -> res[c.idx] = row[c.idx] - m)
        res

    reorder_columns: (columns) ->
        @columns = columns
        @columns_changed = true
        scheduler.schedule('heatmap.render', (() =>
            if !@_is_thinking
                @_render_heatmap()
        ), 200)

    _draw_columns: () ->
        cols = @svg.select('.labels').selectAll('.label')
                   .data(@columns, (c) -> c.name)
        cols.enter().append('text').attr("class","label")
        cols.exit().remove()
        cols.attr("text-anchor", "end")
            .text((d) -> d.name)
            .transition()
            .attr('x', @opts.label_width)
            .attr('y', (d,i) => i * @opts.h + @opts.h/2)
        if @opts.showlegend
            @_make_legend()
        else
            @colorScale = @get_color_scale()

        @columns_changed = false

    _render_heatmap: () ->
        @_thinking(false)

        if (@columns_changed)
            @_draw_columns()

        kept_data = {}
        kept_data[d.id]=d for d in @data

        @cell_w = w = d3.min([@opts.h, (@opts.width - @opts.label_width) / @data.length])

        # Make rows contain only the first that can be distinctly plotted
        rows = []
        last_x = undefined
        for rnum in [0...@order.length]
            x = Math.round(rnum * w)
            if (!last_x? || x!=last_x)
                rows.push({x:x, rest:kept_data[@order[rnum]]})
                last_x = x

        # @_create_brush(w)

        genes = @svg.select(".genes").selectAll("g.gene")
                    .data(rows)

        genes.enter().append("g").attr("class","gene")
        genes.exit().remove()

        cells = genes.selectAll(".cell")
                     .data(((d,rnum) =>
                         res=[]
                         for i,c of @columns
                             res.push {x:d.x, col:i, score: d.rest[c.idx], id: d.rest.id }
                         res),
                         (d) -> d.col)
        cells.enter().append("rect").attr('class','cell')
        cells.attr("width",  Math.ceil(w))
             .attr("height", @opts.h)
             .style("fill", (d) => @colorScale(d.score))
             .attr("x", (d) => d.x)
             .attr("y", (d) => d.col * @opts.h)
             .attr("yloc", (d) => d.yloc)
        cells.exit().remove()

        genes.on('mouseover', (d, loc) =>
            x = d.x
            y = d3.event.pageY
            @dispatch.mouseover(@data_object.row_by_id(d.rest.id), [x, y])
        )
        genes.on('mouseout', () => @dispatch.mouseout())

        #genes.on('mousedown', (e,l) -> console.log 'down', e,l)
        #genes.on('mouseup', (e,l) -> console.log 'up', e,l)
        #genes.on('mousemove', (e,l) -> console.log 'move', e,l)

    on: (t,func) ->
        @dispatch.on(t, func)

    highlight: (rows) ->
        return if !@_enabled || @_is_thinking
        pos = rows.map((r) => @order.indexOf(r.id)).filter((p) -> p>=0)
        #console.log rows,pos
        if pos.length==0
            @unhighlight()
            return

        highlight = @svg.select(".highlight").selectAll(".highlight").data(pos)
        highlight.exit().remove()
        highlight.enter()
                .append("line")
                .attr("class":"arrow highlight")
                .attr("marker-end":"url(#arrow)")
                .attr("y1", @opts.h*@columns.length+20)
                .attr("y2", @opts.h*@columns.length)
        highlight.transition()
                .duration(50)
                .attr("x1", (d) => Math.round((d+0.5)*@cell_w))
                .attr("y1", @opts.h*@columns.length+20)
                .attr("x2": (d) => Math.round((d+0.5)*@cell_w))
                .attr("y2", @opts.h*@columns.length)

    unhighlight: () ->
        @svg.select(".genes").selectAll(".highlight").remove()

    # NOT IN USE - not sure how to get it right.  How should it interact with parallel-coords or ma-plot?
    _create_brush: (w) ->
        # Create brush
        x = d3.scale.identity().domain([0, (@opts.width - @opts.label_width)])
        brush = d3.svg.brush()
             .x(x)
             #.extent([0,200])
             #.on("brush", () -> console.log 'brushed', brush.extent())
             .on("brushend", () =>
                ex = brush.extent()
                data = @svg.selectAll("rect.cell").data()
                d = data.filter((d) -> d.col=='0' && ex[0]<=d.row*w && ex[1]>=d.row*w)
                #console.log "in range=",d
                )

        @svg.select("g.brush").remove()
        gBrush = @svg.append("g")
             .attr("class", "brush")
             .attr("transform", "translate(#{@opts.label_width},0)")
             .call(brush)
            # .call(brush.event)
        gBrush.selectAll("rect")
              .attr("height", 100*@opts.h_pad + @opts.h * @columns.length);

resize = require('./resize-mixin.coffee')

module.exports =
    mixins: [resize]
    props:
        geneData:
            required: true
        genesShow:
            required: true
        dimensions:
            required: true
        highlight: null
        showReplicates:
            type: Boolean
            default: false
        geneOrder:
            default: null
        width:
            default: null
        showlegend:
            default: true
        enablecontextmenu:
            default: true
        twocolor:
            default: false
        infoCols:
            default: null
        avgCol: null
        logfcCol : null
        fdrCol: null
        interactive:
            default: true
    computed:
        needsUpdate: () ->
            # As per https://github.com/vuejs/vue/issues/844#issuecomment-265315349
            this.geneData
            this.dimensions
            Date.now()
        tooltipStyle: () ->
            {left: (this.tooltipLoc[0] + 40)+'px', top: (this.tooltipLoc[1] - 170)+'px'}
    watch:
        needsUpdate: () ->
            this.update_all()

        genesShow: () ->
            this.reFilter()

        highlight: (d) ->
            if d.length>0
                this.heatmap.highlight(d)
            else
                this.heatmap.unhighlight()

        showReplicates: (v) ->
            this.heatmap.opts.show_replicates = v

    data: () ->
        hover: []
        tooltipLoc: [0,0]

    mounted: () ->
        this.heatmap = new Heatmap(
            elem: this.$refs.hmap
            show_replicates: this.showReplicates
            geneOrder: this.geneOrder
            width: this.width
            enablecontextmenu: this.enablecontextmenu
            showlegend: this.showlegend
            twocolor: this.twocolor
        )

        this.heatmap.on("mouseover", (d, loc) => this.show_info(d,loc); this.$emit("mousehover", d))
        this.heatmap.on("mouseout", ()  => this.hide_info())

        this.heatmap.on("hide", () => this.$emit('hide'))
        this.heatmap.on("show_replicates", (v) => this.$emit('show-replicates',v); this.$emit("mousestop"))
        this.update_all()

    methods:
        resize: () ->
            this.heatmap.resize()

        reFilter: () ->
            this.heatmap.schedule_update(this.genesShow)

        update_all: () ->
            if this.dimensions? && this.dimensions.length>0
                this.heatmap.update_columns(this.geneData, this.genesShow, this.dimensions, true)

        show_info: (d,loc) ->
            this.hover=d
            this.tooltipLoc = loc
            this.$emit('hover-start',d,loc)
        hide_info: () ->
            this.hover = []
            this.$emit('hover-end')
        fmt: (val) -> val.toFixed(2)
        fmt2: (val) -> if val<0.01 then val.toExponential(2) else val.toFixed(2)
</script>
