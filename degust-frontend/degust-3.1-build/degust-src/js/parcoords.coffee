class ParCoords
    constructor: (@opts) ->

        d3.select(@opts.elem).style('width', @opts.width) if @opts.width?
        @parcoords = d3.parcoords()(@opts.elem)
            .alpha(0.4)
            .reorderable()
            .brushable() # enable brushing
            .mode('queue')

        @parcoords.setFilter(@opts.filter)

    update_data: (data, dims, extent, coloring) ->
        dim_names = {}
        dims.forEach (k) -> dim_names[k.idx] = k.name
        @parcoords.data(data)
             .dimensions(dims.map((c) -> c.idx))
             .dimension_names(dim_names)
             .autoscale()
        @parcoords.color(coloring) if coloring

        extent ?= ParCoords.calc_extent(data,dims)

        h = @parcoords.height() - @parcoords.margin().top - @parcoords.margin().bottom;
        @parcoords.dimensions().forEach (k) =>
            @parcoords.yscale[k] = d3.scale.linear().domain(extent).range([h+1,1])

        @parcoords.createAxes().render().reorderable().brushable()

        @parcoords.render()
        @parcoords.brush()   # Reset any brushes that were in place

    # Static method 'calc_extent'
    @calc_extent: (data, dims) ->
        # Calculate min/max for all dimensions - Want common scale across dimensions
        extents = []
        dims.forEach (k) ->
            extents.push(d3.extent(data, (v) -> +v[k.idx]))
        extent = d3.extent(d3.merge(extents))
        # Just a bit larger than the extent (so can be brushed over)
        return extent.map((v) -> v*1.05)

    # These methods just pass through
    dimensions: () -> @parcoords.dimensions()
    dimension_names: () -> @parcoords.dimension_names()
    highlight: (d) -> @parcoords.highlight(d)
    unhighlight: () -> @parcoords.unhighlight()
    on: (t,func) -> @parcoords.on(t,func)        # TODO - better abstraction for this
    brush: () -> @parcoords.brush()


window.ParCoords = ParCoords