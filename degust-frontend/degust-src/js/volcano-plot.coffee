class VolcanoPlot extends ScatterPlot
    constructor: (opts) ->
        super(opts)
        @opts = opts
        @opts.name ?= 'Volcano-plot'

        @tooltip = d3.select(@opts.elem).append("div")
                     .attr("class", "tooltip")
                     .style("opacity", 0)

        @on('mouseover.tooltip', (d, loc, loc_doc) => @_show_info(d, loc))
        @on('mouseout.tooltip', () => @_hide_info())

    update_data: (data, @logfc_col, @fdr_col, colour, @info_cols) ->
        super(data,
              {name: "log FC", get: (d) => d[@logfc_col.idx] },
              {name: "-log10 FDR", get: (d) => -Math.log10(d[@fdr_col.idx]) },
              colour)

    # Display and fill in the tooltip
    _show_info: (rows, loc) ->
        fmt  = (val) -> val.toFixed(2)
        fmt2 = (val) -> if val<0.01 then val.toExponential(2) else val.toFixed(2)

        @tooltip.transition().duration(200)
                .style("opacity", 0.8)
        info="<table>"
        row=rows[0]
        @info_cols.forEach((c) ->
            info += "<tr><td><b>#{c.name}</b>:<td>#{row[c.idx]}"
        )
        info += "<tr><td><b>log FC</b>:<td>#{fmt row[@logfc_col.idx]}"
        info += "<tr><td><b>FDR</b>:<td>#{fmt2 row[@fdr_col.idx]}"
        info += "<tr><td><b>-log10 FDR</b>:<td>#{fmt -Math.log10(row[@fdr_col.idx])}"
        info += "</table>"
        if rows.length>1
            info += "(And #{rows.length-1} other#{if rows.length>2 then 's' else ''})"

        @tooltip.html(info)
                .style("left", (loc[0] + 40) + "px")
                .style("top",  (loc[1] + 35) + "px")

    # Hide tooltip
    _hide_info: () ->
        @tooltip.style("opacity", 0)




window.VolcanoPlot = VolcanoPlot
