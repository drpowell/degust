iqr = (k) ->
    (d,i) ->
        q1 = d.quartiles[0]
        q3 = d.quartiles[2]
        r = (q3 - q1) * k
        i = -1
        j = d.length
        while (d[++i] < q1 - r)
            i=i
            # Do nothing
        while (d[--j] > q3 + r)
            i=i
            # Do nothing
        [i, j]

class QC
    @pvalue_histogram: (data) ->
        width = 700
        height = 500

        pval_col = data.columns_by_type('p')[0]
        if !pval_col?
            pval_col = data.columns_by_type('fdr')[0]
        pvals = data.get_data().map((r) -> r[pval_col.idx])
        bins = d3.layout.histogram()
                  .bins(50)(pvals)

        div = $('<div class="pvalue-histogram">')
        div.css(
            'position': 'absolute'
            'top': '80px'
            'left': ($(window).width()-width)/2 + "px"
            'height': (height+10) + "px"
        )
        $("body").append(div)

        barGraph = new BarGraph(
                   elem: div.get(0)
                   tot_width: width
                   tot_height: height
                   margin_t: 50
                   margin_r: 50
                   margin_l: 60
                   margin_b: 50
                   title: "P-value histogram"
                   xlabel: "p-value"
                   ylabel: "number"
                   xdomain: [0,1]
                   xordinal: false
        )
        barGraph.draw(bins.map((b) -> {lbl: b.x, val: b.y, width: b.dx}))
        QC.overlay(div, () -> div.remove())

    @library_size_bargraph: (data, colour) ->
        cols = data.columns_by_type('count')
        lib_sizes = cols.map((c) -> {lbl: c.name, val: data.get_total(c), parent: c.parent})

        width = d3.min([cols.length*30 + 200, 700])
        height = 500

        div = $('<div class="libsize-bargraph">')
        div.css(
            'position': 'absolute'
            'top': '80px'
            'left': ($(window).width()-width)/2 + "px"
            'height': (height+10) + "px"
        )
        $("body").append(div)

        colour ?= d3.scale.category10()
        barGraph = new BarGraph(
                   elem: div.get(0)
                   tot_width: width
                   tot_height: height
                   margin_t: 50
                   margin_r: 90
                   margin_l: 100
                   margin_b: 200
                   rotate_labels: true
                   title: "Library Sizes"
                   xlabel: "library"
                   ylabel: "number of assigned reads"
                   xordinal: true
                   fill: (d) -> colour(d.parent)
        )
        barGraph.draw(lib_sizes)
        QC.overlay(div, () -> div.remove())

    @expression_boxplot: (data, colour) ->
        cpm = QC.get_cpm(data)

        margin = {top: 40, right: 50, bottom: 150, left: 50}
        width_box = 40
        width = width_box * cpm.length + margin.left + margin.right
        box_height = 400
        height = box_height + margin.top + margin.bottom

        div = $('<div class="expression-boxplot"><svg></svg></div>')
        div.css(
            'position': 'absolute'
            'top': '80px'
            'left': ($(window).width()-width)/2 + "px"
            'height': height + "px"
        )
        $("body").append(div)

        colour ?= d3.scale.category10()
        chart = d3.box()
                  .whiskers(iqr(1.5))
                  .width(width_box/2)
                  .height(box_height)
                  .show_values(false)
                  .fill((c) -> colour(c.parent))

        extent = d3.extent([].concat.apply([], cpm.map((r) -> d3.extent(r.vals))))
        chart.domain(extent)

        svg = d3.select(div.get(0))
          .select("svg")
          .attr('height', height)
          .attr('width', width)
        svg.append("text")
             .attr('class', 'title')
             .attr("x", width/2)
             .attr("y", 15)
             .style("text-anchor", "middle")
             .text("Log CPM by library")

        # the x-axis
        x = d3.scale.ordinal()
               .domain( cpm.map((c) -> c.name) )
               .rangeRoundBands([0 , width_box * (cpm.length-1)], 0.7, 0.3)

        svg.selectAll("g.boxplot")
          .data(cpm)
         .enter().append("g")
          .attr("class","boxplot")
          .attr("transform", (d) -> "translate(" + (margin.left + x(d.name)) + "," + margin.top + ")")
          .call(chart)

        xAxis = d3.svg.axis()
                  .scale(x)
                  .orient("bottom")

        # the y-axis
        y = d3.scale.linear()
              .domain(extent)
              .range([box_height + margin.top, 0 + margin.top])

        yAxis = d3.svg.axis()
                  .scale(y)
                  .orient("left")
        # draw y axis
        svg.append("g")
            .attr("class", "y axis")
            .attr("transform", "translate("+(margin.left-20)+",0)")
            .call(yAxis)
            .append("text")
              .attr("transform", "rotate(-90)")
              .attr("y", 6)
              .attr("dy", ".71em")
              .style("text-anchor", "end")
              .style("font-size", "16px")
              .text("log(cpm)")

        # draw x axis
        svg.append("g")
          .attr("class", "x axis")
          .attr("transform", "translate("+(margin.left+5)+"," + (box_height + margin.top + 10) + ")")
          .call(xAxis)
        svg.selectAll(".x.axis .tick text")
              .attr("transform", "rotate(-90) translate(-10,-15)")
              .style("text-anchor", "end")

        get_svg = () ->
            new_svg = d3.select(svg.node().cloneNode(true))
            new_svg.attr('class','');
            Print.copy_svg_style_deep(svg, new_svg)
            {svg: new_svg.node(), width: svg.node().clientWidth, height: svg.node().clientHeight}


        print_menu = (new Print(get_svg, "expression-boxplot")).menu()
        d3.select(div.get(0)).on('contextmenu', d3.contextMenu(print_menu)) # attach menu to element

        QC.overlay(div, () -> div.remove())

    @get_cpm: (data) ->
        cols = data.columns_by_type('count')
        cpm = cols.map((c,i) ->
                norm_factor = data.get_total(c) / 1000000.0
                vals = data.get_data().map((r) -> Math.log(0.5 + r[c.idx]/norm_factor)/Math.log(2))
                {vals: vals, name:c.name, parent:c.parent, pos:i}
                )
        cpm


    @overlay: (elem, closed) ->
        # now the overlay highlight
        elem.addClass('edit-elem')
        over = $('<div class="edit-overlay">')
        elem_back = $('<div class="edit-backdrop">')

        offset = elem.offset()
        offset.top = offset.top-4
        offset.left = offset.left-4
        elem_back.width(elem.innerWidth()+8).height(elem.innerHeight()+8).offset(offset)

        $("body").append(over)
        $("body").append(elem_back)
        over.on('click', () ->
            elem.removeClass('edit-elem')
            over.remove()
            elem_back.remove()
            closed()
        )



window.QC = QC
