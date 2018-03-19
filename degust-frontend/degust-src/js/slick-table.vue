<style scoped>
    div >>> div.tooltip {
      position: absolute;
      text-align: center;
      padding: 6px 12px 6px;
      font: 12px sans-serif;
      background: #333;
      color: #fff;
      border: 0px;
      border-radius: 12px;
      pointer-events: none;
      width: 'auto';
      opacity: 1;
      margin: 0 auto;
      -webkit-transform: translate(-50%, 0); /* Center the tooltip element*/
    }

    div >>> div.tooltip::after {
    content: " ";
    position: absolute;
    top: 100%; /* Place at the bottom of the tooltip */
    left: 50%;
    margin-left: -5px;
    border-width: 5px;
    border-style: solid;
    border-color: black transparent transparent transparent;
}

    div.tooltip table {
      font: 12px sans-serif;
      color: #fff;
    }
</style>

<template>
    <div>
        <div id="grid" ref='outer'></div>
        <div class='tooltip' v-if='showToolTip' :style='tooltipStyle' ref='tooltip'>
            <tr v-html="colName"> <!-- Need to escape colName before it is returned, otherwise risk XSS -->
            </tr>
        </div>
    </div>
</template>

<script lang='coffee'>

# Slick grid
require('./lib/jquery.event.drag-2.2.js')
require('./lib/slick.core.js')
require('./lib/slick.grid.js')
require('./lib/slick.dataview.js')
resize = require('./resize-mixin.coffee')

# Vue wrapper for slick-grid
#   mouseover: callback for row mouse-over
#   mouserout: callback for row mouse-out
#   dblclick: callback for row double-click
module.exports =
    name: 'slick-table'
    mixins: [resize]
    props:
        rows:
            default: []
            required: true
        columns:
            default: []
            required: true
        sorter: null
    data: () ->
        colName: ""
        tooltipLoc: [0,0]
        showToolTip: false
    mounted: () ->
        grid_options =
            enableCellNavigation: true
            enableColumnReorder: false
            multiColumnSort: false
            forceFitColumns: true
            enableTextSelectionOnCells: true

        @dataView = new Slick.Data.DataView(this.$refs.outer)
        @grid = new Slick.Grid(this.$refs.outer, @dataView, [], grid_options)

        @dataView.onRowCountChanged.subscribe( (e, args) =>
          @grid.updateRowCount()
          @grid.render()
          @_update_info()
        )

        @dataView.onRowsChanged.subscribe( (e, args) =>
          @grid.invalidateRows(args.rows)
          @grid.render()
        )

        if this.sorter?
            @grid.onSort.subscribe( (e,args) => this.sorter(args) )
        @grid.onViewportChanged.subscribe( (e,args) => @_update_info() )

        @grid.onHeaderMouseEnter.subscribe((e,args) =>
            val = e.currentTarget.attributes.tooltip.value
            if val == ""
                val = args.column.id
            this.colName = val
            rect = e.currentTarget.getBoundingClientRect()
            this.tooltipLoc = [(rect.left + rect.width / 2) , rect.top]
            this.showToolTip = true
        )
        @grid.onHeaderMouseLeave.subscribe((e,args) =>
            this.showToolTip = false
        )

        # Set up event callbacks
        @grid.onMouseEnter.subscribe( (e,args) =>
            i = @grid.getCellFromEvent(e).row
            d = @dataView.getItem(i)
            this.$emit('mouseover', d)
        )
        @grid.onMouseLeave.subscribe( (e,args) =>
            this.$emit('mouseout')
        )
        @grid.onDblClick.subscribe( (e,args) =>
            this.$emit('dblclick', @grid.getDataItem(args.row))
        )
        this.set_data(true)

    computed:
        # Want to watch rows & cols and issue one update when both change
        rowsAndCols: () ->
            {rows: this.rows, cols: this.columns}
        tooltipStyle: () ->
            {left: (this.tooltipLoc[0])+'px', top: (this.tooltipLoc[1] + window.pageYOffset - 31)+'px'}
    watch:
        rowsAndCols: (n,o) ->
            if n.cols != o.cols
                this.set_data(true)
            else
                this.set_data(false)

    methods:
        resize: () ->
            @grid.resizeCanvas()
            @invalidate()

        resort: () ->
            @dataView.reSort()

        sort: (sorter) ->
            @dataView.sort(sorter)

        get_data: () ->
            @dataView.getItems()

        set_data: (new_columns) ->
            if new_columns
                scheduler.schedule_now('gene_table', () => @set_data_now(new_columns))
            else
                scheduler.schedule('gene_table', () => @set_data_now(new_columns))

        set_data_now: (new_columns) ->
            #console.log "slick-table : set_data_now new_columns=",new_columns
            rows = this.rows.slice()      # Copy the array of rows - we'll need to sort it
            @dataView.beginUpdate()
            @grid.setColumns([]) if new_columns
            @dataView.setItems(rows)
            @dataView.reSort()
            @dataView.endUpdate()
            if new_columns
                @grid.setColumns(this.columns)
                this.$el.querySelectorAll('[title]').forEach((el) -> el.setAttribute("tooltip", el.title))

        # Refresh the view.  Call this when the filter changes
        refresh: () ->
            @dataView.refresh()

        # Redraw the table, use when the content of cells has changed
        invalidate: () ->
            @grid.invalidate()

        _update_info: () ->
            view = @grid.getViewport()
            btm = d3.min [view.bottom, @dataView.getLength()]
            this.$emit('info', {top:view.top, btm:btm, total:@dataView.getLength()})
</script>
