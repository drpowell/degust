# This class handles the drawing and highlighting of kegg pathway images
# Images are just kegg gif images, with the xml definitions used for location of "box" highlighting
class Kegg
    constructor: (@opts) ->
        @ec_visible = {}

    load: (code, @ec_colours, ec_cb) ->
        #console.log ec_colours
        @img_x = undefined
        @kegg_data = undefined

        @img_url = "kegg/pathway/map/map#{code}.gif"
        $(@opts.elem).html("<div id='kegg-container'></div>")

        # Load the image to get the size
        $("<img/>") # Make in memory copy of image to avoid css issues
           .attr("src", @img_url)
            .load((e) =>
                @img_x = e.target.width
                @img_y = e.target.height
                #console.log(@img_x,@img_y)
                @draw_ec()
                )

        d3.xml("kegg/kgml/map/map#{code}.xml", (data) => @xml_loaded(data, ec_cb))

    xml_loaded: (xml, ec_cb) ->
        @kegg_data = @xml_to_list(xml)
        if ec_cb
            ec_codes=[]
            ec_codes = @kegg_data.map (o) -> o.id
            ec_cb(ec_codes) if ec_cb

        @draw_ec()

    draw_ec: () ->
        return if !@kegg_data || !@img_x
        #console.log "drawing"
        d3.select('div#kegg-container').html('')
        @svg = d3.select('div#kegg-container')
                 .append('svg')
                 .attr('viewBox',"1 1 #{@img_x} #{@img_y}")
                 .attr('width','100%')
                 .attr('height','100%')
        @svg.append('image').attr('xlink:href',@img_url)
                            .attr('width',@img_x)
                            .attr('height',@img_y)

        ec_boxes = @svg.selectAll('.ec').data(@kegg_data, (o) -> o.id)
        ec_boxes.enter().append('rect').attr('class','ec')
             .attr('x', (o) -> o.x - o.width/2)
             .attr('y', (o) -> o.y - o.height/2)
             .attr('width',  (o) -> o.width)
             .attr('height', (o) -> o.height)
             .attr('stroke','black')
             .attr('fill-opacity',0.3)
             .attr('fill', (o) => @colour(o.id))

        ec_boxes.exit().remove()

        ec_boxes.on('mouseover', @opts.mouseover) if @opts.mouseover
        ec_boxes.on('mouseout', @opts.mouseout) if @opts.mouseout

    rect: (o) ->
        g.append('rect')

    xml_to_list: (xml) ->
        list = []
        $('entry[type=enzyme] graphics[type=rectangle]',xml).each (i,e_) =>
            e=$(e_)
            o = {id: e.attr('name') }
            if o.id of @ec_colours
                for k in ['x','y','width','height']
                    o[k] = e.attr(k)
                list.push o
        return list

    colour: (ec) ->
        switch @ec_colours[ec]
            when 'same' then 'green'
            when 'mixed' then 'yellow'
            when 'up' then 'red'
            when 'down' then 'blue'
            else 'black'

    highlight: (ec) ->
        if @svg
            @svg.selectAll('.ec').filter( (o) -> o.id == ec).attr('stroke-width',5).attr('stroke','red')
    unhighlight: () ->
        if @svg
            @svg.selectAll('.ec').attr('stroke-width',1).attr('stroke','black')


window.Kegg = Kegg
