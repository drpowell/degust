# Snippet from stackoverflow to invoke a click() d3 will recognise
jQuery.fn.d3Click = () ->
    this.each( (i, e) ->
        evt = document.createEvent("MouseEvents")
        evt.initMouseEvent("click", true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null)

        e.dispatchEvent(evt)
    )

template = "<div class='popover'>          <div class='arrow'></div>          <h3 class='popover-title'></h3>          <div class='popover-content'></div>          <nav class='popover-navigation'>            <div class='btn-group'>              <button class='btn btn-sm btn-default' data-role='prev'>&laquo; Prev</button>              <button class='btn btn-sm btn-default' data-role='next'>Next &raquo;</button>            </div>            <button class='btn btn-sm btn-default' data-role='end'>End tour</button>          </nav>        </div>"

tour_steps =
  [
    title: "<strong>Degust</strong>"
    content: "Degust allows you to explore your Differential Gene Expression data.  You can apply various filters for significance, and see the MA-plot/parallel coordinates plot/heatmap update dynamically.  You can search for specific genes, and download a filtered gene-list."
    orphan: true
    backdrop: true
  ,
    element: '.conditions'
    placement: 'right'
    title:"<strong>Condition selector</strong>"
    content: "Select/deselect the conditions you wish to compare.  Changing these causes the server to re-analyse your data"
  ,
    element: '#expression .nav'
    placement: 'bottom'
    title:"<strong>Select plot type</strong>"
    content: "Select 'Parallel Coordinates' or 'MA plot'.  An 'MA plot' is great for visualising data with just 2 conditions.  The parallel coordinates plot is particuarly useful for more than 2 conditions"
  ,
    element: '#heatmap'
    placement: 'top'
    title:"<strong>Heatmap</strong>"
    content: "<p>The heatmap shows the log fold-change for each gene shown in the plot above.  Each 'vertical strip' corresonds to a gene.  The heatmap may be slow to display when there are many genes to cluster.</p><p>Hovering the mouse over the heatmap will show the corresponding gene in the plot above.</p>"
  ,
    element: '#grid'
    placement: 'top'
    title:"<strong>Gene table</strong>"
    content: "A table of genes filtered to show the same genes as plotted above.  <ul><li>The table may be sorted by clicking on the column headers.<li>Specific genes may be found using the search box<li>Double click a row to open a page for that gene.</ul>"
    template: () -> $(template).addClass('wide')
  ,
    element: '.fdr-fld'
    placement: 'left'
    title:"<strong>FDR threshold</strong>"
    content: "Modify the threshold for False Discovery Rate.  This dynamically filters the plots and gene table below"
  ,
    element: '.fc-fld'
    placement: 'left'
    title:"<strong>Log fold-change threshold</strong>"
    content: "Modify the threshold for absolute log fold-change.  This dynamically filters the plots and gene table below.  For example, a setting of '1.0' will only show genes that have an absolute log fold-change greater than 1.0 (that is 2x up or down) between any pair of conditions."
  ,
    element: '#csv-download'
    placement: 'left'
    backdrop: true
    title:"Gene list download"
    content: "Anything displayed in the gene list table can be downloaded as a CSV file."
  ,
    onShow: () -> $('#select-ma a').click()
    element: '#dge-ma'
    placement: 'bottom'
    title: "<strong>MA plot</strong>"
    content: "<p>An MA plot shows expression for 2 conditions only (as selected in Options).  Each dot on this plot shows a gene.  The x-axis is the average expression, and the y-axis is the log fold-change between the conditions.</p><p>You can click and drag on the plot to select genes within a rectangle - the heatmap and table below will be filtered to only those genes. Click anywhere on the plot to remove a selection rectangle.</p><p>Each dot is coloured by FDR with red being more significant and blue less significant.</p>"
    template: () -> $(template).addClass('wide')
  ,
    onShow: () -> $('#select-pc a').click()
    element: '#dge-pc'
    placement: 'bottom'
    title: "<strong>Parallel Coordinates</strong>"
    content: "<p>Each blue/red line on this plot shows a gene and each axis corresponds to a conditions.  So each line shows the relative expression for a gene across conditions.</p><p>You can select a region of an axis by clicking and dragging vertically on that axis.  This will filter for only genes that fall within the selected fold-change.  Click outside the selection to clear.  Each axis may have an active select region.</p><p>Conditions can be re-ordered by dragging the column header</p><p>Each line is coloured by FDR with red being more significant and blue less significant.</p>"
    template: () -> $(template).addClass('wide')
  ,
    element: '.kegg-filter'
    placement: 'left'
    title: "<strong>Kegg filter</strong>"
    content: '<p>Filter genes by an annotated KEGG pathway.</p><p>The numbers beside each pathway show the number of genes in your dataset annotated in that pathway.  Selecting a pathway will filter to show only those genes, and display the pathway image.  The image may be resized, and you can hover the mouse over EC elements to see genes annotated with that EC.</p><p>The EC elements are coloured: blue = unchanged, green = all up, red = all down, yellow = mixed.</p><p>This KEGG data is from 2007.  If you find this functionality useful, I recommend you purchase a <a href="http://www.bioinformatics.jp/en/keggftp.html">KEGG subscription</a> and run your own local degust server.</p>'
    template: () -> $(template).addClass('wide')

  ]

window.setup_tour = (show_tour) ->
    tour = new Tour(steps: tour_steps)    #({debug: true})
    #window.tour = tour
    tour.init()
    $('a#tour').click(() -> tour.restart())
    tour.start() if show_tour
