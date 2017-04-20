class BarGraph
    constructor: (@opts) ->
        @opts.tot_width  ||= 200
        @opts.tot_height ||= 200
        @opts.margin_t ||= 20
        @opts.margin_l ||= 50
        @opts.margin_r ||= 10
        @opts.margin_b ||= 40
        @opts.ylabel || = ''
        @opts.xlabel || = ''
        @opts.title ||= ''
        @opts.fill ||= () -> 'steelblue'
        @opts.rotate_labels ||= false
        @opts.xordinal = true if !@opts.xordinal?

        margin = {top: @opts.margin_t, right: @opts.margin_r, bottom: @opts.margin_b, left: @opts.margin_l}
        @width = @opts.tot_width - margin.left - margin.right
        @height = @opts.tot_height - margin.top - margin.bottom

        if @opts.xordinal
          @x = d3.scale.ordinal()
                 .rangeRoundBands([0, @width], .1)
        else
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

        @svg_real = d3.select(@opts.elem).append("svg")
                 .attr('class','bar-chart')
                 .attr("width", @width + margin.left + margin.right)
                 .attr("height", @height + margin.top + margin.bottom)
        @svg = @svg_real.append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")")
        @_make_menu(@opts.elem)

    _make_menu: (el) ->
        print_menu = (new Print(@svg_real, @opts.title)).menu()
        d3.select(el).on('contextmenu', d3.contextMenu(print_menu)) # attach menu to element

    draw: (data) ->
        @svg.selectAll("*").remove()
        @x.domain(if @opts.xdomain? then @opts.xdomain else data.map((d) -> d.lbl ))
        @y.domain([0, d3.max(data, (d) -> d.val)])

        @svg.append("text")
             .attr('class', 'title')
             .attr("x", @width/2)
             .attr("y", -10)
             .style("text-anchor", "middle")
             .text(@opts.title)

        @svg.append("g")
             .attr("class", "x axis")
             .attr("transform", "translate(0," + @height + ")")
             .call(@xAxis)
            .append("text")
             .attr('class', 'label')
             .attr("x", @width/2)
             .attr("y", @opts.margin_b-10)
             .style("text-anchor", "middle")
             .text(@opts.xlabel)

        if @opts.rotate_labels
          @svg.selectAll(".x.axis .tick text")
              .attr("transform", "rotate(-90) translate(-10,-15)")
              .style("text-anchor", "end")

        @svg.append("g")
             .attr("class", "y axis")
             .call(@yAxis)
           .append("text")
             .attr('class', 'label')
             .attr("transform", "rotate(-90)")
             .attr("x", -40)
             .attr("y", 20-@opts.margin_l)
             .style("text-anchor", "end")
             .text(@opts.ylabel)

        @svg.selectAll(".bar")
            .data(data)
            .enter().append("rect")
              .attr("class", "bar")
              .attr("x", (d) => @x(d.lbl))
              .attr("width", (d) => if d.width then @x(d.width) else @x.rangeBand())
              .attr("y", (d) => @y(d.val))
              .attr("height", (d) => @height - @y(d.val))
              .attr("fill", (d) => @opts.fill(d))
              .on('click', (d) => if @opts.click? then @opts.click(d))

window.BarGraph = BarGraph