<style scoped>
.mds-plot { width: 570px; height: 400px; }


.mds-plot >>> .scatter .axis text {
    font-family: auto;
    font-size: 100%;
}

.mds-plot >>> .scatter text.axis-label {
    font-weight: bold;
}

.bar-chart >>> .bar:hover { fill: brown; }


.bar-chart >>> .axis path, .bar-chart >>> .axis line {
  fill: none;
  stroke: #000;
  shape-rendering: crispEdges;
}

.bar-chart >>> .axis { font: 10px sans-serif; }
.bar-chart { position: absolute; bottom: 0; left: 510px; }
.bar-chart >>> .x.axis path { display: none; }

</style>

<template>
    <div>
        <scatter-plot class='mds-plot' ref='scatter'
                      :data='components'
                      :x-column='xColumn' :y-column='yColumn'
                      :colour='colour'
                      :text='text'
                      xaxis-loc='bottom' yaxis-loc='left'
                      :animate='true'
                      :canvas='false'>
        </scatter-plot>
        <div class='bar-chart' ref='barchart'>
        </div>
    </div>
</template>

<script lang='coffee'>

require("./lib/numeric-1.2.6.js")
scatter = require('./scatter-plot.vue').default

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


module.exports =
    components:
        scatterPlot: scatter
    props:
        geneData: null
        columns: null
        conditionColouring: null
        filter: null
        filterChanged: null
        numGenes: null
        skipGenes: null
        dimension: null
    data: () ->
        components: []
        xColumn: null
        yColumn: null
    computed:
        needsRedraw: () ->
            this.filterChanged
            this.numGenes
            this.skipGenes
            this.dimension
            Date.now()
    watch:
        geneData: () ->
            this.update_components()
        needsRedraw: () ->
            this.redraw()

    mounted: () ->
            div_bar = this.$refs.barchart
            #@scatter = new ScatterPlot({elem:@div2d.node(), colour: @opts.colour})
            @barGraph = new BarGraph(
                               elem: div_bar
                               title: "% variance by MDS dimension"
                               xlabel: "Dimension"
                               ylabel: "% variance"
                               click: (d) => if @opts.sel_dimension?
                                                 @opts.sel_dimension(d.lbl)
                            )
            this.update_components()
    methods:
        # Note, this is naughty - it writes to the 'data' array a "_variance" column
        # and several "_transformed_" columns.
        # Also, compute the per-column (library) size for later normalization
        update_components: () ->
            console.log "update_components"
            # Compute the library size for each column (for normalising in _compute_variance)
            @norm_cols = Normalize.normalize(this.geneData, this.columns)
            @variances = {}
            @rows = this.geneData.get_data()
            @rows.forEach((row) => @variances[row.id] = @_compute_variance(row))
            @redraw()

        # Convert to log2 counts, and normalize for library size, and compute the gene variance.
        _compute_variance: (row) ->
            vals = @norm_cols.map((col) => row[col.idx])
            PCA.variance(vals)

        redraw: () ->
            console.log "mds redraw"

            # Log transformed counts
            kept_data = @rows.filter((d) => this.filter(d))

            top_genes = kept_data.sort((a,b) => @variances[b.id] - @variances[a.id])
            top_genes = top_genes[this.skipGenes ... (this.skipGenes + this.numGenes)]

            this.$emit('top-genes',top_genes)

            # Get the transformed counts
            transformed = top_genes.map((row) => @norm_cols.map((col) -> row[col.idx]))

            # Transpose to row per sample.
            by_gene = numeric.transpose(transformed)

            pca_results = PCA.pca(by_gene)
            # Now pca_results.pts contains transformed - each row is a sample.  Each column a PCA dimension
            comp = pca_results.pts.map((s, i) => {pts:s, sample: this.columns[i]})

            this.components = comp
            this.xColumn = {name: "MDS Dimension #{this.dimension}", get: (d) => d.pts[this.dimension-1] }
            this.yColumn = {name: "MDS Dimension #{this.dimension+1}", get: (d) => d.pts[this.dimension] }

            #@scatter_draw(plot_2d3d, comp, @columns, dims)

            tot_eigen = d3.sum(pca_results.eigenvalues)
            @barGraph.draw(comp[0..9].map((v,i) ->
                #range = d3.max(v) - d3.min(v)
                range = pca_results.eigenvalues[i]/tot_eigen * 100
                {lbl: "#{i+1}", val: range}
            ))

        # Colour the samples by the parent condition
        colour: (d) ->
            this.conditionColouring(d.sample.parent)
        text: (d) ->
            d.sample.name

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


</script>
