<style scoped>
</style>

<template>
    <div id="grid" ref='outer'>
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
    mounted: () ->
        grid_options =
            enableCellNavigation: true
            enableColumnReorder: false
            multiColumnSort: false
            forceFitColumns: true
            enableTextSelectionOnCells: true

        @dataView = new Slick.Data.DataView()
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

        #@grid.onHeaderMouseEnter.subscribe((e,args) => console.log("enter",e,args))
        #@grid.onHeaderMouseLeave.subscribe((e,args) => console.log("leave",e,args))

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
    computed:
        # Want to watch rows & cols and issue one update when both change
        rowsAndCols: () ->
            {rows: this.rows, cols: this.columns}
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
                $("[title]",this.$el).popover({trigger: 'hover',placement: 'top',container: 'body',html:true})

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
