<style scoped>
.mds-plot { width: 570px; height: 400px; }


.mds-plot >>> .scatter .axis text {
    font-family: auto;
    font-size: 100%;
}

.mds-plot >>> .scatter text.axis-label {
    font-weight: bold;
}


.bar-graph >>> .title {
    font-size: 70%;
    font-weight: bold;
}

.bar-graph >>> .label {
    font-size: 70%;
    font-weight: bold;
}

.bar-graph >>> .bar:hover { fill: brown; }

.bar-graph >>> .axis path, .bar-graph >>> .axis line {
  fill: none;
  stroke: #000;
  shape-rendering: crispEdges;
}

.bar-graph >>> .axis { font: 10px sans-serif; }
.bar-graph >>> .x.axis path { display: none; }

.bar-graph { position: absolute; bottom: 0; right: 0; }

</style>

<template>
    <div>
        <scatter-plot v-if='plot2d3d=="2d"' class='mds-plot' ref='scatter'
                      :data='components'
                      :x-column='xColumn' :y-column='yColumn'
                      :dimensionScale='dimensionScale'
                      :colour='colour'
                      :text='text'
                      xaxis-loc='bottom' yaxis-loc='left'
                      :animate='true'
                      :canvas='false'
                      :margin-t='20'
                      :margin-r='150'
                      :margin-b='40'
                      :margin-l='60'
                      :axis-label-inside='false'
                      >
        </scatter-plot>
        <scatter3d v-if='plot2d3d=="3d"'
                    :data='components'
                    :x-column='xColumn' :y-column='yColumn' :z-column='zColumn'
                    :dimensionScale='dimensionScale'
                    :colour='colour'
                    >
        </scatter3d>
        <bar-graph class='bar-graph'
                  title="% variance by MDS dimension"
                  x-label="Dimension"
                  y-label="% variance"
                  :data='barGraphData'
                  @click='set_dimension'
                  >
        </bar-graph>
    </div>
</template>

<script lang='coffee'>

require("./lib/numeric-1.2.6.js")
{ Normalize } = require('./normalize.coffee')
scatter = require('./scatter-plot.vue').default
scatter3d = require('./scatter3d.vue').default
barGraph = require('./bar-graph.vue').default

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
        scatter3d: scatter3d
        barGraph: barGraph
    props:
        data: null
        columns: null
        conditionColouring: null
        filter: null
        filterChanged: null
        numGenes: null
        skipGenes: null
        dimension: null
        plot2d3d: null
        dimensionScale: null
    data: () ->
        components: []
        xColumn: null
        yColumn: null
        zColumn: null
        barGraphData: []
    computed:
        needsRedraw: () ->
            this.filterChanged
            this.numGenes
            this.skipGenes
            this.dimension
            Date.now()
    watch:
        columns: () ->
            this.update_components()
        needsRedraw: () ->
            this.redraw()

    mounted: () ->
        this.update_components()

    methods:
        # Computes per-row variance (ie. variance for each gene)
        update_components: () ->
            return if !this.data
            startTime = Date.now()
            this.variances = {}
            this.data.forEach((row) => @variances[row.id] = @_compute_variance(row))
            console.log( "MDS normalization took : #{Date.now() - startTime }ms");
            @redraw()

        # Convert to log2 counts, and normalize for library size, and compute the gene variance.
        _compute_variance: (row) ->
            vals = @columns.map((col) => row[col.idx])
            PCA.variance(vals)

        redraw: () ->
            startTime = Date.now()

            # Log transformed counts
            kept_data = this.data.filter((d) => this.filter(d))

            top_genes = kept_data.sort((a,b) => @variances[b.id] - @variances[a.id])
            top_genes = top_genes[this.skipGenes ... (this.skipGenes + this.numGenes)]

            this.$emit('top-genes',top_genes)
            return if top_genes.length==0

            # Get the transformed counts
            transformed = top_genes.map((row) => @columns.map((col) -> row[col.idx]))

            # Transpose to row per sample.
            by_gene = numeric.transpose(transformed)

            pca_results = PCA.pca(by_gene)
            # Now pca_results.pts contains transformed - each row is a sample.  Each column a PCA dimension
            comp = pca_results.pts.map((s, i) => {pts:s, sample: this.columns[i]})

            this.components = comp
            this.xColumn = {name: "MDS Dimension #{this.dimension}", get: (d) => d.pts[this.dimension-1] }
            this.yColumn = {name: "MDS Dimension #{this.dimension+1}", get: (d) => d.pts[this.dimension] }
            this.zColumn = {name: "MDS Dimension #{this.dimension+2}", get: (d) => d.pts[this.dimension+1] }

            tot_eigen = d3.sum(pca_results.eigenvalues)
            this.barGraphData = Vue.noTrack(
                comp[0..9].map((v,i) ->
                    range = pca_results.eigenvalues[i]/tot_eigen * 100
                    {lbl: "#{i+1}", val: range}
                ))
            console.log( "MDS redraw took : #{Date.now() - startTime }ms");


        # Called from bargraph.  Pass it to the parent to set the prop
        set_dimension: (d) ->
            this.$emit("dimension",+d.lbl)

        # Colour the samples by the parent condition
        colour: (d) ->
            this.conditionColouring(d.sample.parent)

        text: (d) ->
            d.sample.name

        brush: () ->
            @redraw()

        highlight: () ->
            # Pass
        unhighlight: () ->
            # Pass

        on: (t,func) ->
            @dispatch.on(t, func)


</script>
