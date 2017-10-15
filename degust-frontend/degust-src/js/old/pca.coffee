
class ScatterPlot
    constructor: (@opts) ->
        elem = @opts.elem
        tot_width = @opts.tot_width || 570
        tot_height = @opts.tot_height || 400
        margin = {top: 20, right: 180, bottom: 40, left: 60}
        @width = tot_width - margin.left - margin.right
        @height = tot_height - margin.top - margin.bottom
        @colour = @opts.colour || d3.scale.category10()

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

        @svg_real = d3.select(elem).append("svg")
                 .attr('class','scatter')
                 .attr("width", @width + margin.left + margin.right)
                 .attr("height", @height + margin.top + margin.bottom)
        @svg = @svg_real.append("g")
                 .attr("transform", "translate(" + margin.left + "," + margin.top + ")")
        @_make_menu(elem)

    _make_menu: (el) ->
        print_menu = (new Print(@svg_real, "MDS-plot")).menu()
        d3.select(el).on('contextmenu', d3.contextMenu(print_menu)) # attach menu to element


    # draw(data,labels)
    #   data - array of rows.  First row is all x-coordinates (dimension 1)
    #                          Second row is all y-coordinates (dimension 2)
    #   labels - array of samples.  sample.name, and (sample.parent for colouring)
    draw: (data, labels, dims) ->
        [dim1,dim2] = dims
        @x.domain(d3.extent(data[dim1-1]))
        @y.domain(d3.extent(data[dim2-1]))

        # Easier to plot with array of
        locs = d3.transpose(data)

        @svg.selectAll(".axis").remove()
        @svg.append("g")
            .attr("class", "x axis")
            .attr("transform", "translate(0," + @height + ")")
            .call(@xAxis)
          .append("text")
            .attr("class", "label")
            .attr("x", @width/2)
            .attr("y", 40)
            .style("text-anchor", "middle")
            .text("MDS Dimension #{dim1}");

        @svg.append("g")
            .attr("class", "y axis")
            .call(@yAxis)
          .append("text")
            .attr("class", "label")
            .attr("transform", "rotate(-90)")
            .attr("x", -100)
            .attr("y", -50)
            .style("text-anchor", "end")
            .text("MDS Dimension #{dim2}");

        dots = @svg.selectAll(".dot")
                   .data(locs)
        dots.exit().remove()

        # Create the dots and labels
        dot_g = dots.enter().append("g")
                    .attr("class", "dot")
        dot_g.append("circle")
             .attr("r", 3.5)
             .attr("cx",0)
             .attr("cy",0)
        dot_g.append("text")
             .attr('class',"labels")
             .attr('x',3)
             .attr('y',-3)

        # Ensure the correct colour and text
        dots.select("circle")
              .style("fill", (d,i) => @colour(labels[i].parent))
        dots.select("text")
              .style("fill", (d,i) => @colour(labels[i].parent))
              .text((d,i) -> labels[i].name)

        # And animate the moving dots
        dots.transition()
            .attr("transform", (d) => "translate(#{@x(d[dim1-1])},#{@y(d[dim2-1])})")

class PCA
    @pca: (matrix) ->
        # We expect 1 row per sample.  Each column is a different gene
        # Subtract column-wise mean (need zero-mean for PCA).
        X = numeric.transpose(numeric.transpose(matrix).map((r) -> mean = 1.0*numeric.sum(r)/r.length; numeric.sub(r,mean)))

        sigma = numeric.dot(X,numeric.transpose(X))
        svd = numeric.svd(sigma)

        # scale the coordinates back
        # (from http://www.ats.ucla.edu/stat/r/pages/svd_demos.htm)
        r = numeric.dot(svd.V, numeric.sqrt(numeric.diag(svd.S)))

        # Want RMS distance (like in Limma), so divide by sqrt(n)
        r = numeric.div(r, Math.sqrt(matrix[0].length))
        {pts: r, eigenvalues: svd.S}

    @variance: (X) ->
        sz = X.length
        numeric.sum(numeric.pow(X,2))/sz - Math.pow(numeric.sum(X),2)/(sz*sz)

class GenePCA
    constructor: (@opts) ->
        @div2d = d3.select(@opts.elem).append("div")
        @div3d = d3.select(@opts.elem).append("div")
        div_bar = d3.select(@opts.elem).append("div")
        @scatter = new ScatterPlot({elem:@div2d.node(), colour: @opts.colour})
        @barGraph = new BarGraph(
                           elem: div_bar.node()
                           title: "% variance by MDS dimension"
                           xlabel: "Dimension"
                           ylabel: "% variance"
                           click: (d) => if @opts.sel_dimension?
                                             @opts.sel_dimension(d.lbl)
                        )
        @dispatch = d3.dispatch("top_genes")

    # Note, this is naughty - it writes to the 'data' array a "_variance" column
    # and several "_transformed_" columns.
    # Also, compute the per-column (library) size for later normalization
    update_data: (@data, @columns) ->
        # Compute the library size for each column (for normalising in _compute_variance)
        @norm_cols = Normalize.normalize(@data, @columns)
        @variances = {}
        @rows = @data.get_data()
        @rows.forEach((row) => @variances[row.id] = @_compute_variance(row))
        @redraw()

    # Convert to log2 counts, and normalize for library size, and compute the gene variance.
    _compute_variance: (row) ->
        vals = @norm_cols.map((col) => row[col.idx])
        PCA.variance(vals)

    redraw: () ->
        {skip:skip_genes, num:num_genes, dims:dims, plot_2d3d: plot_2d3d} = @opts.params()

        # Log transformed counts
        kept_data = @rows.filter((d) => @opts.filter(d))
                       #  .map((row) -> d3.zip(row, lib_size).map(([val,size]) ->

        top_genes = kept_data.sort((a,b) => @variances[b.id] - @variances[a.id])
        top_genes = top_genes[skip_genes ... (skip_genes + num_genes)]

        @dispatch.top_genes(top_genes)

        # Get the transformed counts
        transformed = top_genes.map((row) => @norm_cols.map((col) -> row[col.idx]))

        # Transpose to row per sample.
        by_gene = numeric.transpose(transformed)

        pca_results = PCA.pca(by_gene)
        comp = numeric.transpose(pca_results.pts)
        # 'comp' now contains components.  Each row is a dimension

        @scatter_draw(plot_2d3d, comp, @columns, dims)

        tot_eigen = d3.sum(pca_results.eigenvalues)
        @barGraph.draw(comp[0..9].map((v,i) ->
            #range = d3.max(v) - d3.min(v)
            range = pca_results.eigenvalues[i]/tot_eigen * 100
            {lbl: "#{i+1}", val: range}
        ))

    scatter_draw: (plot_2d3d, comp, cols, dims) ->
        if plot_2d3d=='2d'
            @div2d.style("display","block")
            @div3d.style("display","none")
            @scatter.draw(comp,cols,dims)
        else
            @div2d.style("display","none")
            @div3d.style("display","block")
            DynamicJS.load("./three.js", () =>
                if (!@scatter3d)
                    @scatter3d = new Scatter3d({elem: @div3d.node(), tot_height: 400})
                @scatter3d.update_data(comp, cols, dims)
            )

    brush: () ->
        @redraw()

    highlight: () ->
        # Pass
    unhighlight: () ->
        # Pass

    on: (t,func) ->
        @dispatch.on(t, func)


window.GenePCA = GenePCA
