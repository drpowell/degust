# Table of genes.
# Options
#   elem:  selector for element to put table in
#   elem_info: selector for element to put in paging info
#   mouseover: callback for row mouse-over
#   mouserout: callback for row mouse-out
#   dblclick: callback for row double-click
class GeneTable
    constructor: (@opts) ->
        grid_options =
            enableCellNavigation: true
            enableColumnReorder: false
            multiColumnSort: false
            forceFitColumns: true
            enableTextSelectionOnCells: true

        @dataView = new Slick.Data.DataView()
        @grid = new Slick.Grid(@opts.elem, @dataView, [], grid_options)

        @dataView.setFilter(@opts.filter) if @opts.filter

        @dataView.onRowCountChanged.subscribe( (e, args) =>
          @grid.updateRowCount()
          @grid.render()
          @_update_info()
        )

        @dataView.onRowsChanged.subscribe( (e, args) =>
          @grid.invalidateRows(args.rows)
          @grid.render()
        )

        @grid.onSort.subscribe( (e,args) => @opts.sorter(args) )
        @grid.onViewportChanged.subscribe( (e,args) => @_update_info() )

        # Set up event callbacks
        if @opts.mouseover
            @grid.onMouseEnter.subscribe( (e,args) =>
                i = @grid.getCellFromEvent(e).row
                d = @dataView.getItem(i)
                @opts.mouseover(d)
            )
        if @opts.mouseout
            @grid.onMouseLeave.subscribe( (e,args) =>
                @opts.mouseout()
            )
        if @opts.dblclick
            @grid.onDblClick.subscribe( (e,args) =>
                @opts.dblclick(@grid.getDataItem(args.row))
            )

    sort: (sorter) -> @dataView.sort(sorter)

    get_data: () ->
        @dataView.getItems()

    set_data: (data, columns) ->
        if columns
            scheduler.schedule_now('gene_table', () => @set_data_now(data, columns))
        else
            scheduler.schedule('gene_table', () => @set_data_now(data))

    set_data_now: (data, columns) ->
        @dataView.beginUpdate()
        @grid.setColumns([]) if columns
        @dataView.setItems(data)
        @dataView.reSort()
        @dataView.endUpdate()
        @grid.setColumns(columns) if columns

    # Refresh the view.  Call this when the filter changes
    refresh: () ->
        @dataView.refresh()

    # Redraw the table, use when the content of cells has changed
    invalidate: () ->
        @grid.invalidate()

    _update_info: () ->
        view = @grid.getViewport()
        btm = d3.min [view.bottom, @dataView.getLength()]
        $(@opts.elem_info).html("Showing #{view.top}..#{btm} of #{@dataView.getLength()}")



window.GeneTable = GeneTable